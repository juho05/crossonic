import 'dart:async';

import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class SongListItemViewModel extends ChangeNotifier {
  final FavoritesRepository _favoritesRepository;

  final AudioHandler _audioHandler;
  StreamSubscription? _currentSubscription;
  StreamSubscription? _statusSubscription;

  final Song song;

  bool _favorite = false;
  bool get favorite => _favorite;

  String? _currentSongId;
  PlaybackStatus _playbackStatus = PlaybackStatus.stopped;
  PlaybackStatus? get playbackStatus =>
      _currentSongId == song.id ? _playbackStatus : null;

  SongListItemViewModel({
    required FavoritesRepository favoritesRepository,
    required AudioHandler audioHandler,
    required this.song,
    bool disablePlaybackStatus = false,
  })  : _favoritesRepository = favoritesRepository,
        _audioHandler = audioHandler {
    _favoritesRepository.addListener(_updateFavoriteStatus);

    if (!disablePlaybackStatus) {
      _currentSubscription = _audioHandler.queue.current.listen((current) {
        _currentSongId = current?.id;
        notifyListeners();
      });
      _statusSubscription = _audioHandler.playbackStatus.listen((status) {
        _playbackStatus = status;
        if (_currentSongId == song.id) {
          notifyListeners();
        }
      });
      _currentSongId = _audioHandler.queue.current.value?.id;
      _playbackStatus = _audioHandler.playbackStatus.value;
    }

    _updateFavoriteStatus();
  }

  Future<Result<void>> toggleFavorite() async {
    _favorite = !favorite;
    notifyListeners();
    final result = await _favoritesRepository.setFavorite(
        FavoriteType.song, song.id, favorite);
    if (result is Err) {
      _favorite = !favorite;
      notifyListeners();
    }
    return result;
  }

  Future<void> playPause() async {
    if (_playbackStatus == PlaybackStatus.playing) {
      await _audioHandler.pause();
    } else if (_playbackStatus == PlaybackStatus.paused) {
      await _audioHandler.play();
    }
  }

  void _updateFavoriteStatus() {
    final favorite =
        _favoritesRepository.isFavorite(FavoriteType.song, song.id);
    if (favorite != _favorite) {
      _favorite = favorite;
      notifyListeners();
    }
  }

  void addToQueue(bool priority) {
    _audioHandler.queue.add(song, priority);
  }

  @override
  void dispose() {
    _favoritesRepository.removeListener(_updateFavoriteStatus);
    _currentSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }
}
