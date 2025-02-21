import 'dart:async';

import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class NowPlayingViewModel extends ChangeNotifier {
  final FavoritesRepository _favoritesRepository;
  final AudioHandler _audioHandler;
  late final StreamSubscription _currentSongSubscription;
  late final StreamSubscription _positionSubscription;
  late final StreamSubscription _playbackStatusSubscription;
  late final StreamSubscription _loopSubscription;

  final BehaviorSubject<({Duration position, Duration? bufferedPosition})>
      _position =
      BehaviorSubject.seeded((position: Duration.zero, bufferedPosition: null));
  ValueStream<({Duration position, Duration? bufferedPosition})> get position =>
      _position.stream;

  Song? _song;

  String get songTitle => _song?.title ?? "";
  ({String id, String name})? get album => _song?.album;
  String get displayArtist => _song?.displayArtist ?? "";
  Duration? get duration => _song?.duration;
  String? get coverId => _song?.coverId;
  Iterable<({String id, String name})> get artists => _song?.artists ?? [];

  bool _favorite = false;
  bool get favorite => _favorite;

  PlaybackStatus _playbackStatus = PlaybackStatus.stopped;
  PlaybackStatus get playbackStatus => _playbackStatus;

  bool _loop = false;
  bool get loopEnabled => _loop;

  NowPlayingViewModel({
    required FavoritesRepository favoritesRepository,
    required AudioHandler audioHandler,
  })  : _favoritesRepository = favoritesRepository,
        _audioHandler = audioHandler {
    _favoritesRepository.addListener(_onFavoriteChanged);
    _currentSongSubscription = _audioHandler.currentSong.listen(_onSongChanged);
    _positionSubscription = _audioHandler.position.listen(_onPositionChanged);
    _playbackStatusSubscription =
        _audioHandler.playbackStatus.listen(_onStatusChanged);
    _loopSubscription = _audioHandler.loop.listen(
      (loop) {
        _loop = loop;
        notifyListeners();
      },
    );
  }

  void toggleLoop() async {
    _audioHandler.setLoop(!_loop);
  }

  Future<Result<void>> toggleFavorite() async {
    if (_song == null) return Result.ok(null);
    _favorite = !favorite;
    notifyListeners();
    final result = await _favoritesRepository.setFavorite(
        FavoriteType.song, _song!.id, favorite);
    if (result is Error) {
      _favorite = !favorite;
      notifyListeners();
    }
    return result;
  }

  Future<void> playPause() async {
    if (playbackStatus == PlaybackStatus.playing) {
      await _audioHandler.pause();
    } else {
      await _audioHandler.play();
    }
  }

  Future<void> playNext() async {
    await _audioHandler.playNext();
  }

  Future<void> playPrev() async {
    await _audioHandler.playPrev();
  }

  Future<void> seek(Duration pos) async {
    await _audioHandler.seek(pos);
  }

  void _onStatusChanged(PlaybackStatus status) {
    _playbackStatus = status;
    notifyListeners();
  }

  void _onSongChanged(Song? song) {
    _song = song;
    if (_song == null) {
      _favorite = false;
      return;
    }
    _favorite = _favoritesRepository.isFavorite(FavoriteType.song, _song!.id);
    notifyListeners();
  }

  void _onPositionChanged(
      ({Duration position, Duration? bufferedPosition}) pos) {
    _position.add(pos);
  }

  void _onFavoriteChanged() {
    if (_song == null) return;
    bool old = _favorite;
    _favorite = _favoritesRepository.isFavorite(FavoriteType.song, _song!.id);
    if (old == _favorite) return;
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    _favoritesRepository.removeListener(_onFavoriteChanged);
    await _positionSubscription.cancel();
    await _loopSubscription.cancel();
    await _currentSongSubscription.cancel();
    await _playbackStatusSubscription.cancel();
    super.dispose();
  }
}
