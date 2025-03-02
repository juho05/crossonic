import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/auth/models/server_features.dart';
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

enum AlbumsSortMode {
  random,
  recentlyAdded,
  highestRated,
  frequentlyPlayed,
  recentlyPlayed,
  alphabetical,
  starred,
}

typedef SearchResult = ({
  Iterable<Song> songs,
  Iterable<Album> albums,
  Iterable<Artist> artists,
});

class SubsonicRepository {
  final AuthRepository _auth;
  final SubsonicService _service;
  final FavoritesRepository _favorites;

  ServerFeatures get serverFeatures => _auth.serverFeatures;

  SubsonicRepository({
    required AuthRepository authRepository,
    required SubsonicService subsonicService,
    required FavoritesRepository favoritesRepository,
  })  : _auth = authRepository,
        _service = subsonicService,
        _favorites = favoritesRepository;

  Future<Result<Iterable<Song>>> getStarredSongs() async {
    final result = await _service.getStarred2(_auth.con);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    _updateSongFavorites(result.value.song);
    return Result.ok(
        (result.value.song ?? []).map((c) => Song.fromChildModel(c)));
  }

  Future<Result<SearchResult>> search(
    String query, {
    int? artistCount,
    int? artistOffset,
    int? albumCount,
    int? albumOffset,
    int? songCount,
    int? songOffset,
  }) async {
    final result = await _service.search3(
      _auth.con,
      query,
      artistCount: artistCount,
      artistOffset: artistOffset,
      albumCount: albumCount,
      albumOffset: albumOffset,
      songCount: songCount,
      songOffset: songOffset,
    );
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    _updateArtistFavorites(result.value.artist);
    _updateAlbumFavorites(result.value.album);
    _updateSongFavorites(result.value.song);
    return Result.ok((
      songs: result.value.song?.map((c) => Song.fromChildModel(c)) ?? [],
      albums: result.value.album?.map((a) => Album.fromAlbumID3Model(a)) ?? [],
      artists:
          result.value.artist?.map((a) => Artist.fromArtistID3Model(a)) ?? [],
    ));
  }

  Future<Result<Iterable<Album>>> getAlbums(AlbumsSortMode sort, int count,
      [int offset = 0]) async {
    final result = await _service.getAlbumList2(
      _auth.con,
      switch (sort) {
        AlbumsSortMode.random => AlbumListType.random,
        AlbumsSortMode.recentlyAdded => AlbumListType.newest,
        AlbumsSortMode.highestRated => AlbumListType.highest,
        AlbumsSortMode.frequentlyPlayed => AlbumListType.frequent,
        AlbumsSortMode.recentlyPlayed => AlbumListType.recent,
        AlbumsSortMode.alphabetical => AlbumListType.alphabeticalByName,
        AlbumsSortMode.starred => AlbumListType.starred,
      },
      size: count,
      offset: offset,
    );
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    _updateAlbumFavorites(result.value.album);
    return Result.ok(result.value.album.map((a) => Album.fromAlbumID3Model(a)));
  }

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

  Future<Result<Iterable<Song>>> getRandomSongs({int? count}) async {
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

  Future<Result<List<List<Song>>>> getArtistSongs(Artist artist) async {
    final results =
        await Future.wait((artist.albums ?? []).map((a) => getAlbumSongs(a)));
    final result = <List<Song>>[];
    for (var r in results) {
      switch (r) {
        case Err():
          return Result.error(r.error);
        case Ok():
          result.add(r.value);
      }
    }
    return Result.ok(result);
  }

  Future<Result<List<Song>>> getAlbumSongs(Album album) async {
    if (album.songs != null) return Result.ok(album.songs!);
    final result = await getAlbum(album.id);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    return Result.ok(result.value.songs ?? []);
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
