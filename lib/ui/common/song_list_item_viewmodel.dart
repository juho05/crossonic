import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class SongListItemViewModel extends ChangeNotifier {
  final FavoritesRepository _favoritesRepository;
  final String songId;

  bool _favorite = false;
  bool get favorite => _favorite;

  SongListItemViewModel({
    required FavoritesRepository favoritesRepository,
    required this.songId,
  }) : _favoritesRepository = favoritesRepository {
    _favoritesRepository.addListener(_updateFavoriteStatus);
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
    super.dispose();
  }
}
