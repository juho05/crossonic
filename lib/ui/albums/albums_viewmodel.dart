import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class AlbumsViewModel extends ChangeNotifier {
  final SubsonicRepository _subsonic;
  final AudioHandler _audioHandler;

  static final int _pageSize = 50;

  AlbumsSortMode _mode;
  AlbumsSortMode get mode => _mode;
  set mode(AlbumsSortMode mode) {
    _mode = mode;
    _fetch(0);
  }

  final List<Album> albums = [];

  bool _reachedEnd = false;
  int get _nextPage => (albums.length / _pageSize).ceil();

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  AlbumsViewModel({
    required SubsonicRepository subsonic,
    required AudioHandler audioHandler,
    required AlbumsSortMode mode,
  })  : _subsonic = subsonic,
        _audioHandler = audioHandler,
        _mode = mode;

  Future<void> nextPage() async {
    if (_reachedEnd || _mode == AlbumsSortMode.random) return;
    return await _fetch(_nextPage);
  }

  Future<Result<void>> play(Album album, {bool shuffle = false}) async {
    final result = await _subsonic.getAlbumSongs(album);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    if (shuffle) {
      result.value.shuffle();
    }
    _audioHandler.playOnNextMediaChange();
    _audioHandler.queue.replace(result.value);
    return Result.ok(null);
  }

  Future<Result<void>> addToQueue(Album album, bool priority) async {
    final result = await _subsonic.getAlbumSongs(album);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    _audioHandler.queue.addAll(result.value, priority);
    return Result.ok(null);
  }

  Future<void> _fetch(int page) async {
    if (_status == FetchStatus.loading) return;
    _status = FetchStatus.loading;
    if (page * _pageSize < albums.length) {
      albums.removeRange(page * _pageSize, albums.length);
    }
    notifyListeners();
    final result = await _subsonic.getAlbums(_mode,
        _mode == AlbumsSortMode.random ? 300 : _pageSize, page * _pageSize);
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
