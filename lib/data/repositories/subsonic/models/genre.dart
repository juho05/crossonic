/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/services/opensubsonic/models/genre_model.dart';

class Genre {
  final String name;
  final int songCount;
  final int albumCount;

  Genre({
    required this.name,
    required this.songCount,
    required this.albumCount,
  });

  factory Genre.fromGenreModel(GenreModel g) {
    return Genre(
      name: g.value,
      albumCount: g.albumCount,
      songCount: g.songCount,
    );
  }
}
