import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

enum FavoriteType { song, album, artist }

class FavoritesRepository extends ChangeNotifier {
  final AuthRepository _auth;
  final SubsonicService _subsonic;

  final Set<(FavoriteType, String)> _favoriteIDs = {};

  FavoritesRepository({
    required AuthRepository auth,
    required SubsonicService subsonic,
  })  : _auth = auth,
        _subsonic = subsonic {
    // TODO load data from db
  }

  bool isFavorite(FavoriteType type, String id) {
    return _favoriteIDs.contains((type, id));
  }

  Future<Result<void>> setFavorite(
      FavoriteType type, String id, bool favorite) async {
    if (_favoriteIDs.contains((type, id)) == favorite) return Result.ok(null);

    final Result<void> result;
    if (favorite) {
      result = await _subsonic.star(_auth.con, ids: [
        if (type == FavoriteType.song) id,
      ], albumIds: [
        if (type == FavoriteType.album) id,
      ], artistIds: [
        if (type == FavoriteType.artist) id,
      ]);
    } else {
      result = await _subsonic.unstar(_auth.con, ids: [
        if (type == FavoriteType.song) id,
      ], albumIds: [
        if (type == FavoriteType.album) id,
      ], artistIds: [
        if (type == FavoriteType.artist) id,
      ]);
    }

    if (result is Ok) {
      update(type, id, favorite);
    }

    return result;
  }

  void update(FavoriteType type, String id, bool favorite) {
    if (_favoriteIDs.contains((type, id)) == favorite) return;
    if (favorite) {
      _favoriteIDs.add((type, id));
    } else {
      _favoriteIDs.remove((type, id));
    }
    // TODO persist data in DB
    notifyListeners();
  }

  void updateAll(
      Iterable<({FavoriteType type, String id, bool favorite})> list) {
    bool changed = false;
    for (var e in list) {
      if (e.favorite) {
        changed = _favoriteIDs.add((e.type, e.id)) || changed;
      } else {
        changed = _favoriteIDs.remove((e.type, e.id)) || changed;
      }
    }
    if (changed) {
      // TODO persist data in DB
      notifyListeners();
    }
  }
}
