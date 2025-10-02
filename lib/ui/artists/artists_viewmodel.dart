import 'dart:math';

import 'package:crossonic/data/repositories/subsonic/models/artist.dart';
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

  String? _initialSeed;

  ArtistsViewModel({
    required SubsonicRepository subsonic,
    required ArtistsPageMode mode,
    String? initialSeed,
  })  : _subsonic = subsonic,
        _mode = mode,
        _initialSeed =
            subsonic.supports.randomSeed && mode == ArtistsPageMode.random
                ? initialSeed
                : null;

  Future<void> load() async {
    return await _fetch();
  }

  Future<void> _fetch() async {
    if (_status == FetchStatus.loading) return;
    _status = FetchStatus.loading;
    artists.clear();
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
        if (_initialSeed != null) {
          artists.shuffle(Random(_initialSeed.hashCode));
          _initialSeed = null;
        } else {
          artists.shuffle();
        }
      default:
    }
  }
}
