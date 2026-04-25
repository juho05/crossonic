/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class AlbumListItemViewModel extends ChangeNotifier {
  final FavoritesRepository _favoritesRepository;
  final PlaybackManager _playbackManager;
  final SubsonicRepository _subsonic;

  final Album album;

  bool _favorite = false;

  bool get favorite => _favorite;

  AlbumListItemViewModel({
    required FavoritesRepository favoritesRepository,
    required PlaybackManager playbackManager,
    required SubsonicRepository subsonicRepository,
    required this.album,
  }) : _favoritesRepository = favoritesRepository,
       _playbackManager = playbackManager,
       _subsonic = subsonicRepository {
    _favoritesRepository.addListener(_updateFavoriteStatus);
    _updateFavoriteStatus();
  }

  Future<Result<void>> toggleFavorite() async {
    _favorite = !favorite;
    notifyListeners();
    final result = await _favoritesRepository.setFavorite(
      FavoriteType.album,
      album.id,
      favorite,
    );
    if (result is Err) {
      _favorite = !favorite;
      notifyListeners();
    }
    return result;
  }

  void _updateFavoriteStatus() {
    final favorite = _favoritesRepository.isFavorite(
      FavoriteType.album,
      album.id,
    );
    if (favorite != _favorite) {
      _favorite = favorite;
      notifyListeners();
    }
  }

  Future<Result<void>> play({bool shuffle = false}) async {
    final result = await _subsonic.getAlbumSongs(album);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    if (shuffle) {
      result.value.shuffle();
    }
    _playbackManager.player.playOnNextMediaChange();
    await _playbackManager.queue.replace(result.value);
    return const Result.ok(null);
  }

  Future<Result<void>> addToQueue(bool priority) async {
    final result = await _subsonic.getAlbumSongs(album);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    await _playbackManager.queue.addAll(result.value, priority);
    return const Result.ok(null);
  }

  Future<Result<List<Song>>> getSongs() async {
    return await _subsonic.getAlbumSongs(album);
  }

  @override
  void dispose() {
    _favoritesRepository.removeListener(_updateFavoriteStatus);
    super.dispose();
  }
}
