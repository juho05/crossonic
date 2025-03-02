import 'dart:async';

import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class ArtistGridCellViewModel extends ChangeNotifier {
  final FavoritesRepository _favoritesRepository;

  final String artistId;

  bool _favorite = false;
  bool get favorite => _favorite;

  ArtistGridCellViewModel({
    required FavoritesRepository favoritesRepository,
    required this.artistId,
  }) : _favoritesRepository = favoritesRepository {
    _favoritesRepository.addListener(_updateFavoriteStatus);
    _updateFavoriteStatus();
  }

  Future<Result<void>> toggleFavorite() async {
    _favorite = !favorite;
    notifyListeners();
    final result = await _favoritesRepository.setFavorite(
        FavoriteType.artist, artistId, favorite);
    if (result is Err) {
      _favorite = !favorite;
      notifyListeners();
    }
    return result;
  }

  void _updateFavoriteStatus() {
    final favorite =
        _favoritesRepository.isFavorite(FavoriteType.artist, artistId);
    if (favorite != _favorite) {
      _favorite = favorite;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _favoritesRepository.removeListener(_updateFavoriteStatus);
    super.dispose();
  }
}
