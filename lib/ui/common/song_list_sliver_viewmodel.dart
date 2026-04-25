/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';

class SongListSliverViewModel {
  final PlaybackManager _playbackManager;

  SongListSliverViewModel({required PlaybackManager playbackManager})
    : _playbackManager = playbackManager;

  Future<void> play(List<Song> songs, int songIndex, bool single) async {
    _playbackManager.player.playOnNextMediaChange();
    if (single) {
      await _playbackManager.queue.replace([songs[songIndex]]);
    } else {
      await _playbackManager.queue.replace(songs, songIndex);
    }
  }
}
