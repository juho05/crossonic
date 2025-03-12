import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/services/database/database.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:crossonic/utils/result.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

enum FavoriteType { song, album, artist }

class FavoritesRepository extends ChangeNotifier {
  final AuthRepository _auth;
  final SubsonicService _subsonic;
  final Database _db;

  final Set<(FavoriteType, String)> _favoriteIDs = {};

  FavoritesRepository({
    required AuthRepository auth,
    required SubsonicService subsonic,
    required Database database,
  })  : _auth = auth,
        _subsonic = subsonic,
        _db = database {
    _auth.addListener(_load);
  }

  Future<void> _load() async {
    if (!_auth.isAuthenticated) return;
    final favorites = await _db.managers.favoritesTable.get();
    _favoriteIDs.addAll(
        favorites.map((f) => (FavoriteType.values.byName(f.type), f.id)));
    notifyListeners();

    final result = await _subsonic.getStarred2(_auth.con);
    if (result is Ok) {
      final songs = result.tryValue!.song ?? [];
      final albums = result.tryValue!.album ?? [];
      final artists = result.tryValue!.artist ?? [];
      updateAll(songs
          .map((s) => (id: s.id, type: FavoriteType.song, starred: s.starred))
          .followedBy(albums
              .map((a) =>
                  (id: a.id, type: FavoriteType.album, starred: a.starred))
              .followedBy(artists.map((a) =>
                  (id: a.id, type: FavoriteType.artist, starred: a.starred)))));
    }
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
      update(type, id, DateTime.now());
    }

    return result;
  }

  void update(FavoriteType type, String id, DateTime? starred) {
    if (_favoriteIDs.contains((type, id)) == (starred != null)) return;
    if (starred != null) {
      _favoriteIDs.add((type, id));
      _db.managers.favoritesTable.create(
          (o) => o(id: id, type: type.name, starred: starred),
          mode: InsertMode.replace);
    } else {
      _favoriteIDs.remove((type, id));
      _db.managers.favoritesTable
          .filter((f) => f.id(id) & f.type(type.name))
          .delete();
    }
    notifyListeners();
  }

  void updateAll(
      Iterable<({FavoriteType type, String id, DateTime? starred})> list) {
    bool changed = false;
    for (var e in list) {
      if (e.starred != null) {
        changed = _favoriteIDs.add((e.type, e.id)) || changed;
      } else {
        changed = _favoriteIDs.remove((e.type, e.id)) || changed;
      }
    }
    if (changed) {
      final favorites = list.where((e) => e.starred != null);
      _db.managers.favoritesTable.bulkCreate(
          (o) => favorites
              .map((f) => o(id: f.id, type: f.type.name, starred: f.starred!)),
          mode: InsertMode.replace);
      final notFavoriteSongIDs = list
          .where((e) => e.type == FavoriteType.song && e.starred == null)
          .map((e) => e.id);
      final notFavoriteAlbumIDs = list
          .where((e) => e.type == FavoriteType.album && e.starred == null)
          .map((e) => e.id);
      final notFavoriteArtistIDs = list
          .where((e) => e.type == FavoriteType.artist && e.starred == null)
          .map((e) => e.id);
      _db.managers.favoritesTable
          .filter((f) =>
              (f.type(FavoriteType.song.name) & f.id.isIn(notFavoriteSongIDs)) |
              (f.type(FavoriteType.album.name) &
                  f.id.isIn(notFavoriteAlbumIDs)) |
              (f.type(FavoriteType.artist.name) &
                  f.id.isIn(notFavoriteArtistIDs)))
          .delete();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_load);
    super.dispose();
  }
}
