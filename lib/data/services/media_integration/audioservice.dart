/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audio_service/audio_service.dart' as asv;
import 'package:audio_service_mpris/audio_service_mpris.dart';
import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/services/media_integration/media_integration.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:flutter/foundation.dart';

class AudioServiceIntegration extends asv.BaseAudioHandler
    with asv.SeekHandler
    implements MediaIntegration {
  Future<void> Function()? _onPlay;
  Future<void> Function()? _onPause;
  Future<void> Function(Duration position)? _onSeek;
  Future<void> Function()? _onPlayNext;
  Future<void> Function()? _onPlayPrev;
  Future<void> Function()? _onStop;
  Future<void> Function(double volume)? _onVolumeChanged;
  Future<void> Function(bool loop)? _onLoopChanged;

  @override
  Future<void> ensureInitialized({
    required Future<void> Function() onPlay,
    required Future<void> Function() onPause,
    required Future<void> Function(Duration position) onSeek,
    required Future<void> Function() onPlayNext,
    required Future<void> Function() onPlayPrev,
    required Future<void> Function() onStop,
    required Future<void> Function(double volume) onVolumeChanged,
    required Future<void> Function(bool loop) onLoopChanged,
  }) async {
    if (_onPlay != null) return;
    _onPlay = onPlay;
    _onPause = onPause;
    _onSeek = onSeek;
    _onPlayNext = onPlayNext;
    _onPlayPrev = onPlayPrev;
    _onStop = onStop;
    _onVolumeChanged = onVolumeChanged;
    _onLoopChanged = onLoopChanged;
  }

  @override
  Future<void> play() async {
    Log.debug("audio_service received play action");
    return _onPlay!();
  }

  @override
  Future<void> pause() async {
    Log.debug("audio_service received pause action");
    await _onPause!();
  }

  @override
  Future<void> seek(Duration position) async {
    Log.debug("audio_service received seek action to position $position");
    await _onSeek!(position);
  }

  @override
  Future<void> skipToNext() async {
    Log.trace("audio_service received skipToNext action");
    await _onPlayNext!();
  }

  @override
  Future<void> skipToPrevious() async {
    Log.debug("audio_service received skipToPrevious action");
    await _onPlayPrev!();
  }

  @override
  Future<void> stop() async {
    Log.debug("audio_service received stop action");
    await _onStop!();
  }

  @override
  void updateMedia(Song? song, Uri? coverArt) {
    Log.trace(
      "setting audio_service media to song ${song?.id} with cover: ${SubsonicService.sanitizeUrl(coverArt)}",
    );
    if (song == null) {
      if (!kIsWeb && Platform.isAndroid) {
        mediaItem.add(const asv.MediaItem(id: "", title: "No media"));
      } else {
        mediaItem.add(null);
      }
      playbackState.add(
        playbackState.value.copyWith(
          controls: [],
          systemActions: {},
          androidCompactActionIndices: [],
          processingState: asv.AudioProcessingState.idle,
          playing: false,
        ),
      );
      _positionTimer?.cancel();
      _positionTimer = null;
    } else {
      if (playbackState.value.controls.isEmpty) {
        playbackState.add(
          playbackState.value.copyWith(
            controls: [
              asv.MediaControl.pause,
              asv.MediaControl.play,
              asv.MediaControl.skipToNext,
              asv.MediaControl.skipToPrevious,
              asv.MediaControl.stop,
            ],
            systemActions: {
              asv.MediaAction.pause,
              asv.MediaAction.play,
              asv.MediaAction.playPause,
              asv.MediaAction.seek,
              asv.MediaAction.seekForward,
              asv.MediaAction.seekBackward,
              asv.MediaAction.skipToNext,
              asv.MediaAction.skipToPrevious,
              asv.MediaAction.stop,
              asv.MediaAction.setRepeatMode,
            },
            androidCompactActionIndices: [0, 1],
          ),
        );
      }
      mediaItem.add(
        asv.MediaItem(
          id: song.id,
          title: song.title,
          album: song.album?.name,
          artUri: coverArt,
          artist: song.displayArtist,
          duration: song.duration,
          genre: song.genres.firstOrNull,
          playable: true,
        ),
      );
    }
  }

  Timer? _positionTimer;
  (DateTime, Duration) _positionUpdate = (DateTime.now(), Duration.zero);

  @override
  void updatePlaybackState(PlaybackStatus status) {
    Log.trace("setting audio_service playback state to ${status.name}");
    switch (status) {
      case PlaybackStatus.playing:
        playbackState.add(
          playbackState.value.copyWith(
            playing: true,
            processingState: asv.AudioProcessingState.ready,
            updatePosition: _calculatePosition(),
          ),
        );
      case PlaybackStatus.paused:
        playbackState.add(
          playbackState.value.copyWith(
            playing: false,
            processingState: asv.AudioProcessingState.ready,
            updatePosition: _calculatePosition(),
          ),
        );
      case PlaybackStatus.loading:
        playbackState.add(
          playbackState.value.copyWith(
            playing: false,
            processingState: asv.AudioProcessingState.loading,
            updatePosition: _calculatePosition(),
          ),
        );
      case PlaybackStatus.stopped:
        playbackState.add(
          playbackState.value.copyWith(
            playing: false,
            processingState: asv.AudioProcessingState.idle,
          ),
        );
    }

    // TODO test whether periodic updates are unnecessary on other platforms
    if ((kIsWeb || !Platform.isAndroid) && status == PlaybackStatus.playing) {
      _positionTimer ??= Timer.periodic(
        const Duration(seconds: 1),
        (_) => _updatePosition(),
      );
    } else {
      _positionTimer?.cancel();
      _positionTimer = null;
    }
  }

  @override
  void updatePosition(Duration position) {
    Log.trace("updating audio_service position to $position");
    _positionUpdate = (DateTime.now(), position);
    _updatePosition();
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == "dbusVolume") {
      double v = extras!["value"] as double;
      _onVolumeChanged!(pow(v, 3) as double);
    }
  }

  void _updatePosition() {
    playbackState.add(
      playbackState.value.copyWith(updatePosition: _calculatePosition()),
    );
  }

  Duration _calculatePosition() {
    Duration position = _positionUpdate.$2;
    if (playbackState.value.playing) {
      position += DateTime.now().difference(_positionUpdate.$1);
    }
    return position;
  }

  @override
  Future<void> setRepeatMode(asv.AudioServiceRepeatMode repeatMode) async {
    final loop = repeatMode != asv.AudioServiceRepeatMode.none;
    Log.trace(
      "received audio_service repeat mode ${repeatMode.name}, setting loop to $loop",
    );
    _onLoopChanged?.call(loop);
  }

  @override
  void updateVolume(double volume) {
    if (kIsWeb || !Platform.isLinux) return;
    AudioServiceMpris.updateVolume(volume);
  }

  @override
  void updateLoop(bool loop) {
    playbackState.add(
      playbackState.value.copyWith(
        repeatMode: loop
            ? asv.AudioServiceRepeatMode.all
            : asv.AudioServiceRepeatMode.none,
      ),
    );
  }
}
