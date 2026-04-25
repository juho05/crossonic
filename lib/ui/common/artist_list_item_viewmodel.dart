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
import 'package:crossonic/data/repositories/subsonic/models/artist.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class ArtistListItemViewModel extends ChangeNotifier {
  final FavoritesRepository _favorites;
  final SubsonicRepository _subsonic;
  final PlaybackManager _playbackManager;

  final Artist artist;

  bool _favorite = false;

  bool get favorite => _favorite;

  ArtistListItemViewModel({
    required FavoritesRepository favoritesRepository,
    required SubsonicRepository subsonicRepository,
    required PlaybackManager playbackManager,
    required this.artist,
  }) : _favorites = favoritesRepository,
       _subsonic = subsonicRepository,
       _playbackManager = playbackManager {
    _favorites.addListener(_updateFavoriteStatus);
    _updateFavoriteStatus();
  }

  Future<Result<void>> toggleFavorite() async {
    _favorite = !favorite;
    notifyListeners();
    final result = await _favorites.setFavorite(
      FavoriteType.artist,
      artist.id,
      favorite,
    );
    if (result is Err) {
      _favorite = !favorite;
      notifyListeners();
    }
    return result;
  }

  void _updateFavoriteStatus() {
    final favorite = _favorites.isFavorite(FavoriteType.artist, artist.id);
    if (favorite != _favorite) {
      _favorite = favorite;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _favorites.removeListener(_updateFavoriteStatus);
    super.dispose();
  }

  Future<Result<void>> onAddToQueue(bool priority) async {
    return _subsonic.incrementallyLoadArtistSongs(
      artist,
      (songs, firstBatch) async =>
          await _playbackManager.queue.addAll(songs, priority),
    );
  }

  Future<Result<void>> play({
    bool shuffleAlbums = false,
    bool shuffleSongs = false,
  }) async {
    return _subsonic.incrementallyLoadArtistSongs(
      artist,
      (songs, firstBatch) async {
        if (firstBatch) {
          _playbackManager.player.playOnNextMediaChange();
          await _playbackManager.queue.replace(songs);
          return;
        }
        await _playbackManager.queue.addAll(songs, false);
      },
      shuffleReleases: shuffleAlbums,
      shuffleSongs: shuffleSongs,
    );
  }

  Future<Result<List<Song>>> getSongs() async {
    final result = await _subsonic.getArtistSongs(artist);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
        return Result.ok(result.value.expand((l) => l).toList());
    }
  }
}
