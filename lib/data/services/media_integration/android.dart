/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/services/media_integration/media_integration.dart';
import 'package:crossonic/data/services/methodchannel/method_channel_service.dart';

class MediaIntegrationAndroid implements MediaIntegration {
  final MethodChannelService _methodChannel;

  MediaIntegrationAndroid({required MethodChannelService methodChannel})
    : _methodChannel = methodChannel;

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
    _onPlayNext = onPlayNext;
    _onPlayPrev = onPlayPrev;
    _onLoopChanged = onLoopChanged;

    _methodChannel.addEventListener(_onEvent);
  }

  @override
  void updateLoop(bool loop) {
    // TODO: implement updateLoop
  }

  Future<void> _onEvent(String event, Map<Object?, dynamic>? data) async {
    switch (event) {
      case "playNext":
        await _onPlayNext?.call();
      case "playPrev":
        await _onPlayPrev?.call();
      case "setLoop":
        await _onLoopChanged?.call(data!["loop"]);
    }
  }

  @override
  void updatePosition(Duration position) {
    // already handled by native code
  }

  @override
  void updateMedia(Song? song, Uri? coverArt) {
    // already handled by native code
  }

  @override
  void updatePlaybackState(PlaybackStatus status) {
    // already handled by native code
  }

  @override
  void updateVolume(double volume) {
    // already handled by native code
  }
}
