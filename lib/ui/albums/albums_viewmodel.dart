import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

enum AlbumsPageMode {
  alphabetical,
  favorites,
  random,
  recentlyAdded,
  recentlyPlayed,
  frequentlyPlayed,
  genre
}

class AlbumsViewModel extends ChangeNotifier {
  final SubsonicRepository _subsonic;

  static final int _pageSize = 100;

  AlbumsPageMode _mode;
  AlbumsPageMode get mode => _mode;
  set mode(AlbumsPageMode mode) {
    if (mode == AlbumsPageMode.genre) {
      throw Exception("genre mode can only be set via constructor");
    }
    _mode = mode;
    refresh();
  }

  final List<Album> albums = [];

  bool _reachedEnd = false;
  int get _nextPage => (albums.length / _pageSize).ceil();

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  final String _genre;

  AlbumsViewModel({
    required SubsonicRepository subsonic,
    required AlbumsPageMode mode,
  })  : _subsonic = subsonic,
        _mode = mode,
        _genre = "" {
    if (mode == AlbumsPageMode.genre) {
      throw Exception(
          "cannot set genre mode in default constructor, use genre constructor instead");
    }
    this.mode = mode;
  }

  AlbumsViewModel.genre({
    required SubsonicRepository subsonic,
    required String genre,
  })  : _subsonic = subsonic,
        _mode = AlbumsPageMode.genre,
        _genre = genre {
    _fetch(0);
  }

  Future<void> nextPage() async {
    if (_reachedEnd || _mode == AlbumsPageMode.random) return;
    return await _fetch(_nextPage);
  }

  Future<void> refresh() async {
    return await _fetch(0);
  }

  Future<void> _fetch(int page) async {
    if (_status == FetchStatus.loading) return;
    _status = FetchStatus.loading;
    if (page * _pageSize < albums.length) {
      albums.removeRange(page * _pageSize, albums.length);
    }
    notifyListeners();
    final Result<Iterable<Album>> result;
    if (_mode == AlbumsPageMode.genre) {
      result =
          await _subsonic.getAlbumsByGenre(_genre, _pageSize, page * _pageSize);
    } else {
      result = await _subsonic.getAlbums(
        switch (_mode) {
          AlbumsPageMode.alphabetical => AlbumsSortMode.alphabetical,
          AlbumsPageMode.favorites => AlbumsSortMode.starred,
          AlbumsPageMode.frequentlyPlayed => AlbumsSortMode.frequentlyPlayed,
          AlbumsPageMode.random => AlbumsSortMode.random,
          AlbumsPageMode.recentlyAdded => AlbumsSortMode.recentlyAdded,
          AlbumsPageMode.recentlyPlayed => AlbumsSortMode.recentlyPlayed,
          AlbumsPageMode.genre =>
            AlbumsSortMode.alphabetical, // shouldn't happen
        },
        _mode == AlbumsPageMode.random ? 500 : _pageSize,
        page * _pageSize,
      );
    }
    switch (result) {
      case Err():
        _status = FetchStatus.failure;
        notifyListeners();
        return;
      case Ok():
    }
    _status = FetchStatus.success;
    _reachedEnd = result.value.length < _pageSize;
    albums.addAll(result.value);
    notifyListeners();
  }
}
