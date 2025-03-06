import 'package:crossonic/data/repositories/subsonic/models/genre.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/foundation.dart';

enum GenresSortMode { alphabetical, songCount, albumCount, random }

class GenresViewModel extends ChangeNotifier {
  final SubsonicRepository _subsonic;

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  List<Genre> _genres = [];
  List<Genre> get genres => _genres;

  int _largestSongCount = 0;
  int get largestSongCount => _largestSongCount;
  int _largestAlbumCount = 0;
  int get largestAlbumCount => _largestAlbumCount;

  GenresSortMode _sortMode = GenresSortMode.alphabetical;
  GenresSortMode get sortMode => _sortMode;
  set sortMode(GenresSortMode mode) {
    if (_sortMode == mode && mode != GenresSortMode.random) return;
    _sortMode = mode;
    _sort();
    notifyListeners();
  }

  GenresViewModel({required SubsonicRepository subsonic})
      : _subsonic = subsonic;

  Future<void> load() async {
    if (_status == FetchStatus.loading) return;
    _status = FetchStatus.loading;
    _genres = [];
    _largestSongCount = 0;
    _largestAlbumCount = 0;
    notifyListeners();

    final result = await _subsonic.getGenres();
    switch (result) {
      case Err():
        _status = FetchStatus.failure;
        notifyListeners();
        return;
      case Ok():
    }
    _genres = result.value;
    for (var g in _genres) {
      if (g.albumCount > _largestAlbumCount) _largestAlbumCount = g.albumCount;
      if (g.songCount > _largestSongCount) _largestSongCount = g.songCount;
    }
    _sort();
    _status = FetchStatus.success;
    notifyListeners();
  }

  void _sort() {
    if (sortMode == GenresSortMode.random) {
      _genres.shuffle();
      return;
    }
    _genres.sort((a, b) {
      switch (sortMode) {
        case GenresSortMode.alphabetical:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case GenresSortMode.songCount:
          return b.songCount.compareTo(a.songCount);
        case GenresSortMode.albumCount:
          return b.albumCount.compareTo(a.albumCount);
        case GenresSortMode.random:
          // should not happen
          return 0;
      }
    });
  }
}
