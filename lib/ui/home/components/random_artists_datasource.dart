/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:crossonic/data/repositories/subsonic/models/artist.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/home/components/data_source.dart';
import 'package:crossonic/utils/result.dart';

class RandomArtistsDataSource implements HomeComponentDataSource<Artist> {
  final SubsonicRepository _repository;

  RandomArtistsDataSource({required SubsonicRepository repository})
    : _repository = repository;

  @override
  Future<Result<Iterable<Artist>>> get(int count, {String? seed}) async {
    if (!_repository.supports.randomSeed) seed = null;
    final result = await _repository.getArtists();
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    return Result.ok(
      result.value
          .shuffled(seed != null ? Random(seed.hashCode) : null)
          .take(count),
    );
  }
}
