import 'dart:async';

import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class SongListItemViewModel extends ChangeNotifier {
  final FavoritesRepository _favoritesRepository;

  final AudioHandler _audioHandler;
  StreamSubscription? _currentSubscription;
  StreamSubscription? _statusSubscription;

  final String songId;

  bool _favorite = false;
  bool get favorite => _favorite;

  String? _currentSongId;
  PlaybackStatus _playbackStatus = PlaybackStatus.stopped;
  PlaybackStatus? get playbackStatus =>
      _currentSongId == songId ? _playbackStatus : null;

  SongListItemViewModel({
    required FavoritesRepository favoritesRepository,
    required AudioHandler audioHandler,
    required this.songId,
  })  : _favoritesRepository = favoritesRepository,
        _audioHandler = audioHandler {
    _favoritesRepository.addListener(_updateFavoriteStatus);

    _currentSubscription = _audioHandler.queue.current.listen((current) {
      _currentSongId = current.song?.id;
      notifyListeners();
    });
    _statusSubscription = _audioHandler.playbackStatus.listen((status) {
      _playbackStatus = status;
      notifyListeners();
    });

    _updateFavoriteStatus();
  }

  Future<Result<void>> toggleFavorite() async {
    _favorite = !favorite;
    notifyListeners();
    final result = await _favoritesRepository.setFavorite(
        FavoriteType.song, songId, favorite);
    if (result is Error) {
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
    final favorite = _favoritesRepository.isFavorite(FavoriteType.song, songId);
    if (favorite != _favorite) {
      _favorite = favorite;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _favoritesRepository.removeListener(_updateFavoriteStatus);
    _currentSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }
}
