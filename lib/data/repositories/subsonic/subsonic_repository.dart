import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
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

  Future<Result<List<Song>>> getRandomSongs({required int count}) async {
    final result = await _service.getRandomSongs(_auth.con, count);
    switch (result) {
      case Error():
        return Result.error(result.error);
      case Ok<RandomSongsModel>():
    }
    _favorites.updateAll((result.value.song ?? []).map((c) =>
        (type: FavoriteType.song, id: c.id, favorite: c.starred != null)));
    return Result.ok(
        (result.value.song ?? []).map((c) => _childToSong(c)).toList());
  }

  Song _childToSong(ChildModel child) {
    return Song(
      id: child.id,
      coverId: child.coverArt,
      title: child.title,
      displayArtist: child.displayArtist ??
          child.artists?.map((a) => a.name).join(", ") ??
          child.artist ??
          child.displayAlbumArtist ??
          child.albumArtists?.map((a) => a.name).join(", ") ??
          "Unknown artist",
      artists: child.artists ??
          child.albumArtists ??
          (child.artistId == null && child.artist == null
              ? [(id: child.artistId!, name: child.artist!)]
              : null) ??
          [],
      album: child.albumId != null && child.album != null
          ? (id: child.albumId!, name: child.album!)
          : null,
      genres: child.genres != null
          ? child.genres!.map((g) => g.name)
          : (child.genre != null ? [child.genre!] : []),
      duration:
          child.duration != null ? Duration(seconds: child.duration!) : null,
      year: child.year,
    );
  }

  Uri getCoverUri(String id) {
    final query = _service.generateQuery({
      "id": [id],
    }, _auth.con.auth);
    return Uri.parse(
        '${_auth.con.baseUri}/rest/getCoverArt${Uri(queryParameters: query)}');
  }
}
