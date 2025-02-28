import 'dart:async';

import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class AlbumGridCellViewModel extends ChangeNotifier {
  final FavoritesRepository _favoritesRepository;

  final String albumId;

  bool _favorite = false;
  bool get favorite => _favorite;

  AlbumGridCellViewModel({
    required FavoritesRepository favoritesRepository,
    required this.albumId,
  }) : _favoritesRepository = favoritesRepository {
    _favoritesRepository.addListener(_updateFavoriteStatus);
    _updateFavoriteStatus();
  }

  Future<Result<void>> toggleFavorite() async {
    _favorite = !favorite;
    notifyListeners();
    final result = await _favoritesRepository.setFavorite(
        FavoriteType.album, albumId, favorite);
    if (result is Err) {
      _favorite = !favorite;
      notifyListeners();
    }
    return result;
  }

  void _updateFavoriteStatus() {
    final favorite =
        _favoritesRepository.isFavorite(FavoriteType.album, albumId);
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
