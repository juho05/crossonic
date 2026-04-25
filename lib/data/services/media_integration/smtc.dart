/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/services/media_integration/media_integration.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:flutter/material.dart';
import 'package:smtc_windows/smtc_windows.dart' as smtc;

class SMTCIntegration implements MediaIntegration {
  bool _initialized = false;
  late final smtc.SMTCWindows _smtc;

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
    if (_initialized) return;
    _initialized = true;

    Log.debug("initializing SMTC...");
    await smtc.SMTCWindows.initialize();

    _smtc = smtc.SMTCWindows(
      enabled: true,
      config: const smtc.SMTCConfig(
        fastForwardEnabled: true,
        nextEnabled: true,
        pauseEnabled: true,
        playEnabled: true,
        rewindEnabled: true,
        prevEnabled: true,
        stopEnabled: true,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _smtc.buttonPressStream.listen((event) async {
        Log.debug("received SMTC action: ${event.name}");
        switch (event) {
          case smtc.PressedButton.play:
            await onPlay();
          case smtc.PressedButton.pause:
            await onPause();
          case smtc.PressedButton.stop:
            await onStop();
          case smtc.PressedButton.next:
            await onPlayNext();
          case smtc.PressedButton.previous:
            await onPlayPrev();
          default:
            break;
        }
      });
      _smtc.repeatModeChangeStream.listen((mode) async {
        await onLoopChanged(mode == smtc.RepeatMode.list);
      });
    });
  }

  @override
  void updateMedia(Song? song, Uri? coverArt) {
    Log.trace(
      "setting SMTC media to song ${song?.id} with cover: ${SubsonicService.sanitizeUrl(coverArt)}",
    );
    if (song == null) {
      _smtc.clearMetadata();
    } else {
      _smtc.updateMetadata(
        smtc.MusicMetadata(
          album: song.album?.name,
          artist: song.displayArtist,
          thumbnail: coverArt?.toString(),
          title: song.title,
        ),
      );
    }
  }

  @override
  void updatePlaybackState(PlaybackStatus status) {
    Log.trace("setting SMTC playback state to ${status.name}");
    switch (status) {
      case PlaybackStatus.playing:
        _smtc.setPlaybackStatus(smtc.PlaybackStatus.playing);
      case PlaybackStatus.paused:
        _smtc.setPlaybackStatus(smtc.PlaybackStatus.paused);
      case PlaybackStatus.stopped:
        _smtc.setPlaybackStatus(smtc.PlaybackStatus.stopped);
      default:
        break;
    }
  }

  @override
  void updatePosition(
    Duration position, [
    Duration bufferedPosition = Duration.zero,
  ]) {
    // is displayed nowhere and causes bugs when called repeatedly
  }

  @override
  void updateVolume(double volume) {}

  @override
  void updateLoop(bool loop) {
    _smtc.setRepeatMode(loop ? smtc.RepeatMode.list : smtc.RepeatMode.none);
  }
}
