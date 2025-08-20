import 'dart:async';

import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/artist.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class ArtistListItemViewModel extends ChangeNotifier {
  final FavoritesRepository _favorites;
  final SubsonicRepository _subsonic;
  final AudioHandler _audioHandler;

  final Artist artist;

  bool _favorite = false;
  bool get favorite => _favorite;

  ArtistListItemViewModel({
    required FavoritesRepository favoritesRepository,
    required SubsonicRepository subsonicRepository,
    required AudioHandler audioHandler,
    required this.artist,
  })  : _favorites = favoritesRepository,
        _subsonic = subsonicRepository,
        _audioHandler = audioHandler {
    _favorites.addListener(_updateFavoriteStatus);
    _updateFavoriteStatus();
  }

  Future<Result<void>> toggleFavorite() async {
    _favorite = !favorite;
    notifyListeners();
    final result =
        await _favorites.setFavorite(FavoriteType.artist, artist.id, favorite);
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
      (songs, firstBatch) async => _audioHandler.queue.addAll(songs, priority),
    );
  }

  Future<Result<void>> play(
      {bool shuffleAlbums = false, bool shuffleSongs = false}) async {
    return _subsonic.incrementallyLoadArtistSongs(
      artist,
      (songs, firstBatch) async {
        if (firstBatch) {
          _audioHandler.playOnNextMediaChange();
          _audioHandler.queue.replace(songs);
          return;
        }
        _audioHandler.queue.addAll(songs, false);
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
