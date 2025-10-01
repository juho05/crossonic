import 'dart:math';

import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/data/repositories/subsonic/models/album_info.dart';
import 'package:crossonic/data/repositories/subsonic/models/artist.dart';
import 'package:crossonic/data/repositories/subsonic/models/artist_info.dart';
import 'package:crossonic/data/repositories/subsonic/models/genre.dart';
import 'package:crossonic/data/repositories/subsonic/models/listenbrainz_config.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/server_support.dart';
import 'package:crossonic/data/services/opensubsonic/exceptions.dart';
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

typedef ScanStatus = ({
  bool scanning,
  int? scanned,
  bool? isFullScan,
  DateTime? scanStart,
  DateTime? lastScan,
});

class SubsonicRepository {
  final AuthRepository _auth;
  final SubsonicService _service;
  final FavoritesRepository _favorites;

  ServerSupport get supports => ServerSupport(features: _auth.serverFeatures);

  SubsonicRepository({
    required AuthRepository authRepository,
    required SubsonicService subsonicService,
    required FavoritesRepository favoritesRepository,
  })  : _auth = authRepository,
        _service = subsonicService,
        _favorites = favoritesRepository;

  Future<Result<List<String>>> getLyricsLines(Song song) async {
    if (!supports.songLyricsById) {
      final result =
          await _service.getLyrics(_auth.con, song.displayArtist, song.title);
      switch (result) {
        case Ok():
          return Result.ok(result.tryValue!.value.split("\n"));
        case Err():
      }
      if (result.error is SubsonicException) {
        final e = result.error as SubsonicException;
        if (e.code == SubsonicErrorCode.notFound) {
          return const Result.ok([]);
        }
      }
      return Result.error(result.error);
    }

    final result = await _service.getLyricsBySongId(_auth.con, song.id);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    final lyrics = result.value.structuredLyrics.firstOrNull?.line ?? [];
    return Result.ok(lyrics.map((l) => l.value).toList());
  }

  Future<Result<Iterable<Album>>> getAlbumsByGenre(String genre, int count,
      [int offset = 0]) async {
    final result = await _service.getAlbumList2(
      _auth.con,
      AlbumListType.byGenre,
      genre: genre,
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

  Future<Result<List<Song>>> getSongs({
    String? search,
    bool onlyFavorites = false,
    int? minBpm,
    int? maxBpm,
    int? fromYear,
    int? toYear,
    List<String> genres = const [],
    List<String> artistIds = const [],
    List<String> albumIds = const [],
    SongsSortMode? sort,
    bool orderDesc = false,
    String? seed,
    int? count,
    int? offset,
  }) async {
    final result = await _service.getSongs(
      _auth.con,
      search: search,
      starred: onlyFavorites,
      minBpm: minBpm,
      maxBpm: maxBpm,
      fromYear: fromYear,
      toYear: toYear,
      genres: genres,
      artistIds: artistIds,
      albumIds: albumIds,
      orderBy: sort,
      orderDesc: orderDesc,
      seed: seed,
      count: count,
      offset: offset,
    );
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    _updateSongFavorites(result.value.song);
    return Result.ok(
        (result.value.song ?? []).map((c) => Song.fromChildModel(c)).toList());
  }

  Future<Result<List<Song>>> getSongsByGenre(
    String genre, {
    int? count,
    int? offset,
  }) async {
    final result = await _service.getSongsByGenre(_auth.con, genre,
        count: count, offset: offset);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    _updateSongFavorites(result.value.song);
    return Result.ok(
        (result.value.song ?? []).map((c) => Song.fromChildModel(c)).toList());
  }

  Future<Result<List<Genre>>> getGenres() async {
    final result = await _service.getGenres(_auth.con);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    return Result.ok((result.value.genre ?? [])
        .map((g) => Genre.fromGenreModel(g))
        .toList());
  }

  Future<Result<ListenBrainzConfig>> connectListenBrainz(String token) async {
    final result = await _service.connectListenBrainz(_auth.con, token);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    return Result.ok(
        ListenBrainzConfig.fromListenBrainzConfigModel(result.value));
  }

  Future<Result<ListenBrainzConfig>> updateListenBrainzConfig(
      {bool? scrobble, bool? syncFeedback}) async {
    final result = await _service.updateListenBrainzConfig(_auth.con,
        scrobble: scrobble, syncFeedback: syncFeedback);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    return Result.ok(
        ListenBrainzConfig.fromListenBrainzConfigModel(result.value));
  }

  Future<Result<ListenBrainzConfig>> disconnectListenBrainz() async {
    return connectListenBrainz("");
  }

  Future<Result<ListenBrainzConfig>> getListenBrainzConfig() async {
    final result = await _service.getListenBrainzConfig(_auth.con);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    return Result.ok(
        ListenBrainzConfig.fromListenBrainzConfigModel(result.value));
  }

  Future<Result<ScanStatus>> startScan({
    bool fullScan = false,
  }) async {
    final result = await _service.startScan(_auth.con, fullScan: fullScan);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
        return Result.ok((
          scanning: result.value.scanning,
          scanned: result.value.count,
          isFullScan: result.value.isFullScan,
          lastScan: result.value.lastScan,
          scanStart: result.value.startTime,
        ));
    }
  }

  Future<Result<ScanStatus>> getScanStatus() async {
    final result = await _service.getScanStatus(_auth.con);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
        return Result.ok((
          scanning: result.value.scanning,
          scanned: result.value.count,
          isFullScan: result.value.isFullScan,
          lastScan: result.value.lastScan,
          scanStart: result.value.startTime,
        ));
    }
  }

  Future<Result<Iterable<Artist>>> getArtists() async {
    final result = await _service.getArtists(_auth.con);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    final artistModels = (result.value.index ?? [])
        .expand((i) => (i.artist ?? <ArtistID3Model>[]));
    _updateArtistFavorites(artistModels);
    return Result.ok(artistModels.map((a) => Artist.fromArtistID3Model(a)));
  }

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

  Future<Result<Iterable<Artist>>> getStarredArtists() async {
    final result = await _service.getStarred2(_auth.con);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    _updateArtistFavorites(result.value.artist);
    return Result.ok(
        (result.value.artist ?? []).map((a) => Artist.fromArtistID3Model(a)));
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
      onlyAlbumArtists: supports.searchOnlyAlbumArtistsParam ? false : null,
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

  Future<Result<Iterable<Album>>> getAlbumsByYears(
      int fromYear, int toYear, int count,
      [int offset = 0]) async {
    final result = await _service.getAlbumList2(
      _auth.con,
      AlbumListType.byYear,
      fromYear: fromYear,
      toYear: toYear,
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

  Future<Result<Iterable<Album>>> getAlternateAlbumVersions(
      String albumId) async {
    if (!supports.getAlternateAlbumVersions) {
      return const Result.ok([]);
    }
    final result = await _service.getAlternateAlbumVersions(_auth.con, albumId);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    _updateAlbumFavorites(result.value.album);
    return Result.ok(result.value.album.map((a) => Album.fromAlbumID3Model(a)));
  }

  Future<Result<Iterable<Album>>> getAppearsOn(String artistId) async {
    if (!supports.appearsOn) {
      return const Result.ok([]);
    }
    final result = await _service.getAppearsOn(_auth.con, artistId);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    _updateAlbumFavorites(result.value.album);
    return Result.ok(result.value.album.map((a) => Album.fromAlbumID3Model(a)));
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

  Uri getCoverUri(String id, {int? size, bool constantSalt = false}) {
    return _service.getCoverUri(_auth.con, id,
        size: size, constantSalt: constantSalt);
  }

  Future<Result<List<List<Song>>>> getAlbumsSongs(List<Album> albums) async {
    // using Future.wait causes long delay (triggers timeout)
    // for some reason doing the requests sequentially is much faster
    final result = <List<Song>>[];
    for (var a in albums) {
      final r = await getAlbumSongs(a);
      switch (r) {
        case Err():
          return Result.error(r.error);
        case Ok():
          result.add(r.value);
      }
    }
    return Result.ok(result);
  }

  Future<Result<List<List<Song>>>> getArtistSongs(Artist artist) async {
    final albums = await getArtistAlbums(artist);
    switch (albums) {
      case Err():
        return Result.error(albums.error);
      case Ok():
    }
    return getAlbumsSongs(albums.value);
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

  Future<Result<void>> incrementallyLoadSongs(
    Iterable<Album> albums,
    Future<void> Function(List<Song> songs, bool firstBatch) songsLoaded, {
    bool shuffleAlbums = false,
    bool shuffleSongs = false,
  }) async {
    if (shuffleSongs) {
      shuffleAlbums = true;
    }
    if (albums.isEmpty) {
      return const Result.ok(null);
    }
    final albumList = List.of(albums);
    if (shuffleAlbums) {
      albumList.shuffle();
    }
    final firstSongs = await getAlbumSongs(albumList.first);
    switch (firstSongs) {
      case Err():
        return Result.error(firstSongs.error);
      case Ok():
    }

    final songs = <Song>[];
    bool firstBatch = true;
    if (firstSongs.value.isNotEmpty) {
      if (shuffleSongs) {
        final song = firstSongs.value
            .removeAt(Random().nextInt(firstSongs.value.length));
        await songsLoaded([song], firstBatch);
        firstBatch = false;
        songs.addAll(firstSongs.value);
      } else {
        await songsLoaded(firstSongs.value, firstBatch);
        firstBatch = false;
      }
    }

    if (albumList.length > 1) {
      for (final a in albumList.sublist(1)) {
        final result = await getAlbumSongs(a);
        switch (result) {
          case Err():
            Log.error("Failed to load album songs: ${result.error}");
            continue;
          case Ok():
        }
        songs.addAll(result.value);
      }
    }
    if (shuffleSongs) {
      songs.shuffle();
    }
    await songsLoaded(songs, firstBatch);
    firstBatch = false;
    return const Result.ok(null);
  }

  Future<Result<void>> incrementallyLoadArtistSongs(
    Artist artist,
    Future<void> Function(List<Song> songs, bool firstBatch) songsLoaded, {
    bool shuffleReleases = false,
    bool shuffleSongs = false,
  }) async {
    final albums = await getArtistAlbums(artist);
    switch (albums) {
      case Err():
        return Result.error(albums.error);
      case Ok():
    }
    return incrementallyLoadSongs(
      albums.value,
      songsLoaded,
      shuffleAlbums: shuffleReleases,
      shuffleSongs: shuffleSongs,
    );
  }

  Future<Result<List<Album>>> getArtistAlbums(Artist artist) async {
    if (artist.albums != null) return Result.ok(artist.albums!);

    final result = await getArtist(artist.id);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    return Result.ok(result.value.albums ?? []);
  }

  void _updateArtistFavorites(Iterable<ArtistID3Model>? artists) {
    _favorites.updateAll((artists ?? [])
        .map((a) => (type: FavoriteType.artist, id: a.id, starred: a.starred)));
    _updateAlbumFavorites((artists ?? []).expand((a) => a.album ?? []));
  }

  void _updateAlbumFavorites(Iterable<AlbumID3Model>? albums) {
    _favorites.updateAll((albums ?? [])
        .map((a) => (type: FavoriteType.album, id: a.id, starred: a.starred)));
    _updateSongFavorites((albums ?? []).expand((a) => a.song ?? []));
  }

  void _updateSongFavorites(Iterable<ChildModel>? songs) {
    _favorites.updateAll((songs ?? [])
        .map((c) => (type: FavoriteType.song, id: c.id, starred: c.starred)));
  }
}
