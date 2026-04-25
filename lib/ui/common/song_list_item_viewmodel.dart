/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class SongListItemViewModel extends ChangeNotifier {
  final FavoritesRepository _favoritesRepository;

  final PlaybackManager _playbackManager;
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
    required PlaybackManager playbackManager,
    required this.song,
    bool disablePlaybackStatus = false,
  }) : _favoritesRepository = favoritesRepository,
       _playbackManager = playbackManager {
    _favoritesRepository.addListener(_updateFavoriteStatus);

    if (!disablePlaybackStatus) {
      _currentSubscription = _playbackManager.queue.current.listen((current) {
        _currentSongId = current?.id;
        notifyListeners();
      });
      _statusSubscription = _playbackManager.player.playbackStatus.listen((
        status,
      ) {
        _playbackStatus = status;
        if (_currentSongId == song.id) {
          notifyListeners();
        }
      });
      _currentSongId = _playbackManager.queue.current.value?.id;
      _playbackStatus = _playbackManager.player.playbackStatus.value;
    }

    _updateFavoriteStatus();
  }

  Future<Result<void>> toggleFavorite() async {
    _favorite = !favorite;
    notifyListeners();
    final result = await _favoritesRepository.setFavorite(
      FavoriteType.song,
      song.id,
      favorite,
    );
    if (result is Err) {
      _favorite = !favorite;
      notifyListeners();
    }
    return result;
  }

  Future<void> play() async {
    await _playbackManager.player.play();
  }

  Future<void> pause() async {
    await _playbackManager.player.pause();
  }

  Future<void> playSong() async {
    _playbackManager.player.playOnNextMediaChange();
    await _playbackManager.queue.replace([song]);
  }

  void _updateFavoriteStatus() {
    final favorite = _favoritesRepository.isFavorite(
      FavoriteType.song,
      song.id,
    );
    if (favorite != _favorite) {
      _favorite = favorite;
      notifyListeners();
    }
  }

  void addToQueue(bool priority) {
    _playbackManager.queue.add(song, priority);
  }

  @override
  void dispose() {
    _favoritesRepository.removeListener(_updateFavoriteStatus);
    _currentSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }
}
