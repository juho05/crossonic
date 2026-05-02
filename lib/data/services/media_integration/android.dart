/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/data/repositories/cover/cover_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/services/media_integration/media_integration.dart';
import 'package:crossonic/data/services/methodchannel/android_mediaitem.dart';
import 'package:crossonic/data/services/methodchannel/method_channel_service.dart';

class MediaIntegrationAndroid implements MediaIntegration {
  final MethodChannelService _methodChannel;
  final CoverRepository _coverRepo;

  MediaIntegrationAndroid({
    required MethodChannelService methodChannel,
    required CoverRepository coverRepo,
  }) : _methodChannel = methodChannel,
       _coverRepo = coverRepo;

  Future<void> Function()? _onPlay;
  Future<void> Function()? _onPause;
  Future<void> Function()? _onStop;
  Future<void> Function()? _onPlayNext;
  Future<void> Function()? _onPlayPrev;
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
    _onPlay = onPlay;
    _onPause = onPause;
    _onStop = onStop;
    _onPlayNext = onPlayNext;
    _onPlayPrev = onPlayPrev;
    _onLoopChanged = onLoopChanged;

    _methodChannel.addEventListener(_onEvent);
  }

  @override
  void updateLoop(bool loop) {
    // TODO
  }

  Future<void> _onEvent(String event, Map<Object?, dynamic>? data) async {
    Log.debug("event received: $event");
    switch (event) {
      case "playNext":
        await _onPlayNext?.call();
      case "playPrev":
        await _onPlayPrev?.call();
      case "setLoop":
        await _onLoopChanged?.call(data!["loop"]);
      case "play":
        await _onPlay?.call();
      case "pause":
        Log.debug("calling pause: $_onPause");
        await _onPause?.call();
      case "stop":
        await _onStop?.call();
    }
  }

  @override
  void updatePosition(Duration position) {
    _methodChannel.invokeMethod("updatePosition", {
      "pos": position.inMilliseconds,
    });
  }

  @override
  void updateMedia(Song? song, Uri? coverArt) async {
    _methodChannel.invokeMethod("updateMedia", {
      "media": await _songToMap(song),
    });
  }

  @override
  void updatePlaybackState(PlaybackStatus status) {
    _methodChannel.invokeMethod("updatePlaybackState", {"status": status.name});
  }

  @override
  void updateVolume(double volume) {
    // TODO
  }

  Future<Map<String, dynamic>?> _songToMap(Song? s) async {
    if (s == null) return null;
    final coverKey = CoverRepository.getKey(s.coverId, 512);
    final coverFile = await _coverRepo.getFileFromCache(coverKey);
    if (coverFile == null) {
      _coverRepo
          .getSingleFile(coverKey)
          .then(
            (file) async {
              final bytes = await file.readAsBytes();
              _methodChannel.invokeMethod("updateCover", {
                "songId": s.id,
                "coverBytes": bytes,
              });
            },
            onError: (err) {
              // ignore
            },
          );
    }
    return AndroidMediaItem(
      id: s.id,
      browsable: false,
      playable: true,
      title: s.title,
      album: s.album?.name,
      artist: s.displayArtist,
      discNumber: s.discNr,
      durationMs: s.duration?.inMilliseconds,
      genre: s.genres.firstOrNull,
      trackNumber: s.trackNr,
      releaseYear: s.releaseDate?.year,
      releaseMonth: s.releaseDate?.month,
      releaseDay: s.releaseDate?.day,
      artworkData: await coverFile?.file.readAsBytes(),
    ).toMsgData();
  }
}
