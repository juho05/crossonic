import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/data/repositories/subsonic/models/album_info.dart';
import 'package:crossonic/data/repositories/subsonic/models/artist.dart';
import 'package:crossonic/data/repositories/subsonic/models/artist_info.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/services/opensubsonic/models/albumid3_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/artistid3_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/child_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/random_songs_model.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:crossonic/utils/result.dart';

class SubsonicRepository {
  final AuthRepository _auth;
  final SubsonicService _service;
  final FavoritesRepository _favorites;
  SubsonicRepository({
    required AuthRepository authRepository,
    required SubsonicService subsonicService,
    required FavoritesRepository favoritesRepository,
  })  : _auth = authRepository,
        _service = subsonicService,
        _favorites = favoritesRepository;

  Future<Result<ArtistInfo>> getArtistInfo(String id) async {
    final result = await _service.getArtistInfo2(_auth.con, id);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    return Result.ok(ArtistInfo.fromArtistInfo2Model(result.value));
  }

  Future<Result<Artist>> getArtist(String id) async {
    final result = await _service.getArtist(_auth.con, id);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    _updateArtistFavorites([result.value]);
    return Result.ok(Artist.fromArtistID3Model(result.value));
  }

  Future<Result<Album>> getAlbum(String id) async {
    final result = await _service.getAlbum(_auth.con, id);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    _updateAlbumFavorites([result.value]);
    return Result.ok(Album.fromAlbumID3Model(result.value));
  }

  Future<Result<AlbumInfo>> getAlbumInfo(String id) async {
    final result = await _service.getAlbumInfo2(_auth.con, id);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    return Result.ok(AlbumInfo.fromAlbumInfoModel(result.value));
  }

  Future<Result<List<Song>>> getRandomSongs({int? count}) async {
    final result = await _service.getRandomSongs(_auth.con, size: count);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok<RandomSongsModel>():
    }
    _updateSongFavorites(result.value.song);
    return Result.ok(
        (result.value.song ?? []).map((c) => Song.fromChildModel(c)).toList());
  }

  Uri getCoverUri(String id) {
    final query = _service.generateQuery({
      "id": [id],
    }, _auth.con.auth);
    return Uri.parse(
        '${_auth.con.baseUri}/rest/getCoverArt${Uri(queryParameters: query)}');
  }

  void _updateArtistFavorites(Iterable<ArtistID3Model>? artists) {
    _favorites.updateAll((artists ?? []).map((a) =>
        (type: FavoriteType.artist, id: a.id, favorite: a.starred != null)));
    _updateAlbumFavorites((artists ?? []).expand((a) => a.album ?? []));
  }

  void _updateAlbumFavorites(Iterable<AlbumID3Model>? albums) {
    _favorites.updateAll((albums ?? []).map((a) =>
        (type: FavoriteType.album, id: a.id, favorite: a.starred != null)));
    _updateSongFavorites((albums ?? []).expand((a) => a.song ?? []));
  }

  void _updateSongFavorites(Iterable<ChildModel>? songs) {
    _favorites.updateAll((songs ?? []).map((c) =>
        (type: FavoriteType.song, id: c.id, favorite: c.starred != null)));
  }
}
