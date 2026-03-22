/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';

class SongListSliverViewModel {
  final AudioHandler _audioHandler;
  SongListSliverViewModel({required AudioHandler audioHandler})
    : _audioHandler = audioHandler;

  Future<void> play(List<Song> songs, int songIndex, bool single) async {
    _audioHandler.playOnNextMediaChange();
    if (single) {
      await _audioHandler.queue.replace([songs[songIndex]]);
    } else {
      await _audioHandler.queue.replace(songs, songIndex);
    }
  }
}
