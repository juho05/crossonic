import 'dart:async';

import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class BpmViewModel extends ChangeNotifier {
  final SubsonicRepository _subsonic;
  final AudioHandler _audioHandler;

  static final int _pageSize = 500;

  Timer? _rangeChangeDebounce;
  RangeValues _bpmRange = const RangeValues(45, 205);
  RangeValues get bpmRange => _bpmRange;
  set bpmRange(RangeValues range) {
    _bpmRange = range;
    notifyListeners();
    _rangeChangeDebounce?.cancel();
    _rangeChangeDebounce =
        Timer(const Duration(milliseconds: 500), () => refresh());
  }

  final List<Song> songs = [];

  bool _reachedEnd = false;
  int get _nextPage => (songs.length / _pageSize).ceil();

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  BpmViewModel({
    required SubsonicRepository subsonic,
    required AudioHandler audioHandler,
  })  : _subsonic = subsonic,
        _audioHandler = audioHandler;

  Future<void> nextPage() async {
    if (_reachedEnd) return;
    return await _fetch(_nextPage);
  }

  Future<void> refresh() async {
    _rangeChangeDebounce?.cancel();
    _rangeChangeDebounce = null;
    return await _fetch(0);
  }

  void play() async {
    _audioHandler.playOnNextMediaChange();
    _audioHandler.queue.replace(songs);
  }

  void shuffle() async {
    final s = List.of(songs)..shuffle();
    _audioHandler.playOnNextMediaChange();
    _audioHandler.queue.replace(s);
  }

  void addToQueue(bool priority) async {
    _audioHandler.queue.addAll(songs, priority);
  }

  Future<void> _fetch(int page) async {
    if (_status == FetchStatus.loading) return;
    _status = FetchStatus.loading;
    if (page * _pageSize < songs.length) {
      songs.removeRange(page * _pageSize, songs.length);
    }
    notifyListeners();
    final result = await _subsonic.getSongs(
      sort: SongsSortMode.bpm,
      count: _pageSize,
      offset: page * _pageSize,
      minBpm: bpmRange.start < 50 ? 0 : bpmRange.start.round(),
      maxBpm: bpmRange.end > 200 ? null : bpmRange.end.round(),
    );
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

  @override
  void dispose() {
    _rangeChangeDebounce?.cancel();
    super.dispose();
  }
}
