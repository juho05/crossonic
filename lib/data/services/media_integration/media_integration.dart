/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';

export 'audioservice.dart';
export 'smtc_stub.dart' if (dart.library.ffi) 'smtc.dart';

abstract interface class MediaIntegration {
  Future<void> ensureInitialized({
    required Future<void> Function() onPlay,
    required Future<void> Function() onPause,
    required Future<void> Function(Duration position) onSeek,
    required Future<void> Function() onPlayNext,
    required Future<void> Function() onPlayPrev,
    required Future<void> Function() onStop,
    required Future<void> Function(double volume) onVolumeChanged,
    required Future<void> Function(bool loop) onLoopChanged,
  });

  void updateLoop(bool loop);

  void updatePosition(Duration position);

  void updateMedia(Song? song, Uri? coverArt);

  void updatePlaybackState(PlaybackStatus status);

  void updateVolume(double volume);
}
