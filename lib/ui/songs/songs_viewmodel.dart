import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

enum SongsPageMode {
  all,
  random,
  favorites,
}

class SongsViewModel extends ChangeNotifier {
  final SubsonicRepository _subsonic;
  final AudioHandler _audioHandler;

  static final int _pageSize = 500;

  bool get supportsAllMode => _subsonic.serverFeatures.isOpenSubsonic;

  SongsPageMode _mode = SongsPageMode.random;
  SongsPageMode get mode => _mode;
  set mode(SongsPageMode mode) {
    if (!supportsAllMode && mode == SongsPageMode.all) {
      mode = SongsPageMode.random;
    }
    _mode = mode;
    _fetch(0);
  }

  final List<Song> songs = [];

  bool _reachedEnd = false;
  int get _nextPage => (songs.length / _pageSize).ceil();

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  SongsViewModel({
    required SubsonicRepository subsonic,
    required AudioHandler audioHandler,
    required SongsPageMode mode,
  })  : _subsonic = subsonic,
        _audioHandler = audioHandler {
    this.mode = mode;
  }

  Future<void> nextPage() async {
    if (_reachedEnd ||
        _mode == SongsPageMode.random ||
        _mode == SongsPageMode.favorites) {
      return;
    }
    return await _fetch(_nextPage);
  }

  void play(int index) async {
    _audioHandler.playOnNextMediaChange();
    _audioHandler.queue.replace(songs, index);
  }

  void shuffle() async {
    final s = List.of(songs)..shuffle();
    _audioHandler.playOnNextMediaChange();
    _audioHandler.queue.replace(s);
  }

  void addAllToQueue(bool priority) async {
    _audioHandler.queue.addAll(songs, priority);
  }

  void addToQueue(Song song, bool priority) async {
    _audioHandler.queue.add(song, priority);
  }

  Future<void> _fetch(int page) async {
    if (_status == FetchStatus.loading) return;
    _status = FetchStatus.loading;
    if (page * _pageSize < songs.length) {
      songs.removeRange(page * _pageSize, songs.length);
    }
    notifyListeners();
    final Result<Iterable<Song>> result;
    switch (_mode) {
      case SongsPageMode.random:
        result = await _subsonic.getRandomSongs(count: _pageSize);
      case SongsPageMode.all:
        final r = await _subsonic.search(
          "",
          songCount: _pageSize,
          songOffset: page * _pageSize,
          albumCount: 0,
          artistCount: 0,
        );
        switch (r) {
          case Err():
            result = Result.error(r.error);
          case Ok():
            result = Result.ok(r.value.songs);
        }
      case SongsPageMode.favorites:
        result = await _subsonic.getStarredSongs();
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
    songs.addAll(result.value);
    notifyListeners();
  }
}
