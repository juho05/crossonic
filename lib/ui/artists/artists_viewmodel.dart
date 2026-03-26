/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:math';

import 'package:crossonic/data/repositories/subsonic/models/artist.dart';
import 'package:crossonic/data/repositories/subsonic/music_folders_repository.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

enum ArtistsPageMode { alphabetical, favorites, random }

class ArtistsViewModel extends ChangeNotifier {
  final SubsonicRepository _subsonic;

  ArtistsPageMode _mode;
  ArtistsPageMode get mode => _mode;
  set mode(ArtistsPageMode mode) {
    final old = _mode;
    _mode = mode;
    if (_mode == ArtistsPageMode.favorites ||
        old == ArtistsPageMode.favorites) {
      _fetch();
    } else {
      _sortArtists();
      notifyListeners();
    }
  }

  final List<Artist> artists = [];

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  final String? _initialSeed;
  String? _seed;

  StreamSubscription? _musicFolderSub;

  ArtistsViewModel({
    required SubsonicRepository subsonic,
    required ArtistsPageMode mode,
    required MusicFoldersRepository musicFolders,
    String? initialSeed,
  }) : _subsonic = subsonic,
       _mode = mode,
       _initialSeed = initialSeed {
    _musicFolderSub = musicFolders.debounced.listen((event) {
      load(keepSeed: true);
    });
  }

  Future<void> load({bool keepSeed = false}) async {
    return await _fetch(keepSeed: keepSeed);
  }

  Future<void> _fetch({bool keepSeed = false}) async {
    if (_status == FetchStatus.loading) return;
    _status = FetchStatus.loading;
    artists.clear();

    if (_subsonic.supports.randomSeed) {
      if (_seed == null && _initialSeed != null) {
        _seed = _initialSeed;
      } else if (!keepSeed) {
        _seed = Random().nextDouble().toString();
      }
    }

    notifyListeners();

    final Result<Iterable<Artist>> result;

    if (_mode == ArtistsPageMode.favorites) {
      result = await _subsonic.getStarredArtists();
    } else {
      result = await _subsonic.getArtists();
    }

    switch (result) {
      case Err():
        _status = FetchStatus.failure;
        notifyListeners();
        return;
      case Ok():
    }

    artists.addAll(result.value);
    _sortArtists();
    _status = FetchStatus.success;
    notifyListeners();
  }

  void _sortArtists() {
    switch (_mode) {
      case ArtistsPageMode.alphabetical:
        artists.sort((a, b) => a.name.compareTo(b.name));
      case ArtistsPageMode.random:
        if (_seed != null) {
          artists.shuffle(Random(_seed.hashCode));
        } else {
          artists.shuffle();
        }
      default:
    }
  }

  @override
  void dispose() {
    _musicFolderSub?.cancel();
    super.dispose();
  }
}
