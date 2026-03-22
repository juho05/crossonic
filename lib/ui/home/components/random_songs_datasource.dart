/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/home/components/data_source.dart';
import 'package:crossonic/utils/result.dart';

class RandomSongsDataSource implements HomeComponentDataSource<Song> {
  final SubsonicRepository _repository;

  RandomSongsDataSource({required SubsonicRepository repository})
    : _repository = repository;

  @override
  Future<Result<Iterable<Song>>> get(int count, {String? seed}) async {
    if (!_repository.supports.randomSeed) seed = null;
    return await _repository.getRandomSongs(count: count, seed: seed);
  }
}
