import 'dart:convert';

import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/services/opensubsonic/auth.dart';
import 'package:crossonic/data/services/opensubsonic/exceptions.dart';
import 'package:crossonic/data/services/opensubsonic/models/album_info_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/album_list2_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/albumid3_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/artist_info2_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/artistid3_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/artists_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/genres_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/listenbrainz_config_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/lyrics_list_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/lyrics_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/opensubsonic_extension_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/playlist_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/playlists_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/random_songs_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/scan_status_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/search_result3_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/server_info.dart';
import 'package:crossonic/data/services/opensubsonic/models/songs_by_genre_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/starred2_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/token_info_model.dart';
import 'package:crossonic/utils/exceptions.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum AlbumListType {
  random,
  newest,
  highest,
  frequent,
  recent,
  alphabeticalByName,
  alphabeticalByArtist,
  starred,
  byYear,
  byGenre,
}

class SubsonicService {
  static const String _clientName = "crossonic";
  static const String _protocolVersion = "1.16.1";

  Future<Result<void>> updatePlaylist(
    Connection con,
    String playlistId, {
    String? name,
    String? comment,
    Iterable<String> songIdToAdd = const [],
    Iterable<int> songIndexToRemove = const [],
  }) async {
    return await _fetchJson(
      con,
      "updatePlaylist",
      {
        "playlistId": [playlistId],
        "name": name != null ? [name] : [],
        "comment": comment != null ? [comment] : [],
        "songIdToAdd": songIdToAdd,
        "songIndexToRemove": songIndexToRemove.map((i) => i.toString()),
      },
      null,
    );
  }

  Future<Result<void>> setPlaylistCover(
      Connection con, String id, String mime, Uint8List cover) async {
    final queryParams = generateQuery({
      "id": [id],
    }, con.auth);
    final queryStr = Uri(queryParameters: queryParams).query;
    try {
      final response = await http.post(
          Uri.parse('${con.baseUri}/rest/crossonic/setPlaylistCover?$queryStr'),
          body: cover,
          headers: {"Content-Type": mime}).timeout(const Duration(minutes: 2));
      if (response.statusCode != 200 && response.statusCode != 201) {
        return Result.error(ServerException(response.statusCode));
      }
    } catch (e) {
      return Result.error(ConnectionException());
    }
    return Result.ok(null);
  }

  Future<Result<PlaylistsModel>> getPlaylists(Connection con) async {
    return await _fetchObject(
      con,
      "getPlaylists",
      {},
      PlaylistsModel.fromJson,
      "playlists",
    );
  }

  Future<Result<PlaylistModel>> getPlaylist(Connection con, String id) async {
    return await _fetchObject(
      con,
      "getPlaylist",
      {
        "id": [id],
      },
      PlaylistModel.fromJson,
      "playlist",
    );
  }

  Future<Result<void>> deletePlaylist(Connection con, String id) async {
    return _fetchJson(
      con,
      "deletePlaylist",
      {
        "id": [id],
      },
      null,
    );
  }

  Future<Result<PlaylistModel>> createPlaylist(
    Connection con, {
    String? playlistId,
    String? playlistName,
    Iterable<String> songIds = const [],
  }) async {
    return await _fetchObject(
      con,
      "createPlaylist",
      {
        "playlistId": playlistId != null ? [playlistId] : [],
        "name": playlistName != null ? [playlistName] : [],
        "songId": songIds,
      },
      PlaylistModel.fromJson,
      "playlist",
    );
  }

  Future<Result<SongsByGenreModel>> getSongsByGenre(
    Connection con,
    String genre, {
    int? count,
    int? offset,
  }) async {
    return await _fetchObject(
        con,
        "getSongsByGenre",
        {
          "genre": [genre],
          "count": count != null ? [count.toString()] : [],
          "offset": offset != null ? [offset.toString()] : [],
        },
        SongsByGenreModel.fromJson,
        "songsByGenre");
  }

  Future<Result<LyricsModel>> getLyrics(
      Connection con, String artist, String title) async {
    return await _fetchObject(
        con,
        "getLyrics",
        {
          "title": [title],
          "artist": [artist],
        },
        LyricsModel.fromJson,
        "lyrics");
  }

  Future<Result<LyricsListModel>> getLyricsBySongId(
      Connection con, String id) async {
    return await _fetchObject(
      con,
      "getLyricsBySongId",
      {
        "id": [id],
      },
      LyricsListModel.fromJson,
      "lyricsList",
    );
  }

  Future<Result<GenresModel>> getGenres(Connection con) async {
    return _fetchObject(con, "getGenres", {}, GenresModel.fromJson, "genres");
  }

  Future<Result<void>> scrobble(
      Connection con,
      Iterable<({String songId, DateTime time, Duration listenDuration})>
          scrobbles,
      bool submission,
      bool includeListenDuration) async {
    if (scrobbles.isEmpty) return Result.ok(null);
    assert(
      scrobbles.length == 1 || submission,
      "cannot set multiple now playing (submission == false) scrobbles",
    );
    return await _fetchJson(
      con,
      "scrobble",
      {
        "id": scrobbles.map((s) => s.songId),
        "time": scrobbles.map((s) => s.time.millisecondsSinceEpoch.toString()),
        "submission": [submission.toString()],
        "duration_ms": includeListenDuration
            ? scrobbles.map((s) => s.listenDuration.inMilliseconds.toString())
            : [],
      },
      null,
    );
  }

  Future<Result<ListenBrainzConfigModel>> getListenBrainzConfig(
      Connection con) async {
    return await _fetchObject(con, "crossonic/getListenBrainzConfig", {},
        ListenBrainzConfigModel.fromJson, "listenBrainzConfig");
  }

  Future<Result<ListenBrainzConfigModel>> connectListenBrainz(
      Connection con, String token) async {
    return await _fetchObject(
        con,
        "crossonic/connectListenBrainz",
        {
          "token": [token],
        },
        ListenBrainzConfigModel.fromJson,
        "listenBrainzConfig");
  }

  Future<Result<ScanStatusModel>> startScan(Connection con) async {
    return await _fetchObject(
        con, "startScan", {}, ScanStatusModel.fromJson, "scanStatus");
  }

  Future<Result<ScanStatusModel>> getScanStatus(Connection con) async {
    return await _fetchObject(
        con, "getScanStatus", {}, ScanStatusModel.fromJson, "scanStatus");
  }

  Future<Result<ArtistsModel>> getArtists(Connection con) async {
    return await _fetchObject(
        con, "getArtists", {}, ArtistsModel.fromJson, "artists");
  }

  Future<Result<SearchResult3Model>> search3(
    Connection con,
    String query, {
    int? artistCount,
    int? artistOffset,
    int? albumCount,
    int? albumOffset,
    int? songCount,
    int? songOffset,
  }) async {
    return _fetchObject(
      con,
      "search3",
      {
        "query": [query],
        "artistCount": artistCount != null ? [artistCount.toString()] : [],
        "artistOffset": artistOffset != null ? [artistOffset.toString()] : [],
        "albumCount": albumCount != null ? [albumCount.toString()] : [],
        "albumOffset": albumOffset != null ? [albumOffset.toString()] : [],
        "songCount": songCount != null ? [songCount.toString()] : [],
        "songOffset": songOffset != null ? [songOffset.toString()] : [],
      },
      SearchResult3Model.fromJson,
      "searchResult3",
    );
  }

  Future<Result<AlbumList2Model>> getAlbumList2(
    Connection con,
    AlbumListType type, {
    int? size,
    int? offset,
    int? fromYear,
    int? toYear,
    String? genre,
  }) async {
    return await _fetchObject(
        con,
        "getAlbumList2",
        {
          "type": [type.name],
          "size": size != null ? [size.toString()] : [],
          "offset": offset != null ? [offset.toString()] : [],
          "fromYear": fromYear != null ? [fromYear.toString()] : [],
          "toYear": toYear != null ? [toYear.toString()] : [],
          "genre": genre != null ? [genre] : [],
        },
        AlbumList2Model.fromJson,
        "albumList2");
  }

  Future<Result<ArtistInfo2Model>> getArtistInfo2(Connection con, String id,
      {int? count, bool? includeNotPresent}) {
    return _fetchObject(
      con,
      "getArtistInfo2",
      {
        "id": [id],
        "count": count != null ? [count.toString()] : [],
        "includeNotPresent":
            includeNotPresent != null ? [includeNotPresent.toString()] : [],
      },
      ArtistInfo2Model.fromJson,
      "artistInfo2",
    );
  }

  Future<Result<ArtistID3Model>> getArtist(Connection con, String id) async {
    return _fetchObject(
      con,
      "getArtist",
      {
        "id": [id]
      },
      ArtistID3Model.fromJson,
      "artist",
    );
  }

  Future<Result<AlbumInfoModel>> getAlbumInfo2(Connection con, String id) {
    return _fetchObject(
      con,
      "getAlbumInfo2",
      {
        "id": [id],
      },
      AlbumInfoModel.fromJson,
      "albumInfo",
    );
  }

  Future<Result<AlbumID3Model>> getAlbum(Connection con, String id) {
    return _fetchObject(
        con,
        "getAlbum",
        {
          "id": [id],
        },
        AlbumID3Model.fromJson,
        "album");
  }

  Future<Result<void>> star(
    Connection con, {
    Iterable<String> ids = const [],
    Iterable<String> albumIds = const [],
    Iterable<String> artistIds = const [],
  }) async {
    return await _fetchJson(
        con,
        "star",
        {
          "id": ids,
          "albumId": albumIds,
          "artistId": artistIds,
        },
        null);
  }

  Future<Result<void>> unstar(
    Connection con, {
    Iterable<String> ids = const [],
    Iterable<String> albumIds = const [],
    Iterable<String> artistIds = const [],
  }) async {
    return await _fetchJson(
        con,
        "unstar",
        {
          "id": ids,
          "albumId": albumIds,
          "artistId": artistIds,
        },
        null);
  }

  Future<Result<Starred2Model>> getStarred2(Connection con) async {
    return await _fetchObject(
        con, "getStarred2", {}, Starred2Model.fromJson, "starred2");
  }

  Future<Result<RandomSongsModel>> getRandomSongs(
    Connection con, {
    int? size,
    String? genre,
    int? fromYear,
    int? toYear,
  }) async {
    return await _fetchObject(
      con,
      "getRandomSongs",
      {
        if (size != null) "size": [size.toString()],
        if (genre != null) "genre": [genre],
        if (fromYear != null) "fromYear": [fromYear.toString()],
        if (toYear != null) "toYear": [toYear.toString()],
      },
      RandomSongsModel.fromJson,
      "randomSongs",
    );
  }

  Future<Result<void>> ping(Connection con) async {
    return _fetchJson(con, "ping", {}, null);
  }

  Future<Result<Iterable<OpenSubsonicExtensionModel>>>
      getOpenSubsonicExtensions(Connection con) async {
    return _fetchList(con, "getOpenSubsonicExtensions", {},
        OpenSubsonicExtensionModel.fromJson, "openSubsonicExtensions");
  }

  Future<Result<TokenInfoModel>> tokenInfo(Connection con) async {
    return await _fetchObject(
        con, "tokenInfo", {}, TokenInfoModel.fromJson, "tokenInfo");
  }

  Future<Result<ServerInfo>> fetchServerInfo(Uri baseUri) async {
    final result = await _request(baseUri, "ping", {}, EmptyAuth(), false);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok<http.Response>():
    }
    final response = result.value;
    try {
      final json =
          response.headers["content-type"]?.contains("charset") ?? false
              ? response.body
              : utf8.decode(response.bodyBytes);
      Map<String, dynamic> body = jsonDecode(json);
      if (!body.containsKey("subsonic-response")) {
        return Result.error(
            UnexpectedResponseException("subsonic-response object missing"));
      }
      final res = body["subsonic-response"] as Map<String, dynamic>;
      if (!res.containsKey("version")) {
        return Result.error(
            UnexpectedResponseException("version field missing"));
      }

      final version = res["version"] as String;

      return Result.ok(ServerInfo(
        subsonicVersion: version,
        serverVersion:
            res.containsKey("serverVersion") ? res["serverVersion"] : null,
        type: res.containsKey("type") ? res["type"] : null,
        isOpenSubsonic: res.containsKey("openSubsonic") && res["openSubsonic"],
        isCrossonic: res.containsKey("crossonic") && res["crossonic"],
      ));
    } catch (e) {
      return Result.error(UnexpectedResponseException(e.toString()));
    }
  }

  Future<Result<T>> _fetchObject<T>(
    Connection con,
    String endpointName,
    Map<String, Iterable<String>> queryParams,
    T Function(Map<String, dynamic>) fromJson,
    String responseKey,
  ) async {
    final result =
        await _fetchJson(con, endpointName, queryParams, responseKey);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok<dynamic>():
        return Result.ok(fromJson(result.value));
    }
  }

  Future<Result<Iterable<T>>> _fetchList<T>(
    Connection con,
    String endpointName,
    Map<String, Iterable<String>> queryParams,
    T Function(Map<String, dynamic>) fromJson,
    String responseKey,
  ) async {
    final result =
        await _fetchJson(con, endpointName, queryParams, responseKey);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok<dynamic>():
        final list = result.value as List<dynamic>;
        return Result.ok(
            list.map((dynamic obj) => fromJson(obj as Map<String, dynamic>)));
    }
  }

  Future<Result<dynamic>> _fetchJson(
    Connection con,
    String endpointName,
    Map<String, Iterable<String>> queryParams,
    String? responseKey,
  ) async {
    try {
      final result = await _request(
          con.baseUri, endpointName, queryParams, con.auth, con.supportsPost);
      switch (result) {
        case Err():
          return Result.error(result.error);
        case Ok<http.Response>():
      }
      final response = result.value;
      final json =
          response.headers["content-type"]?.contains("charset") ?? false
              ? response.body
              : utf8.decode(response.bodyBytes);
      Map<String, dynamic> body = jsonDecode(json);
      if (!body.containsKey("subsonic-response")) {
        return Result.error(
            UnexpectedResponseException("subsonic-response object missing"));
      }
      final res = body["subsonic-response"] as Map<String, dynamic>;
      if (!res.containsKey("status")) {
        return Result.error(
            UnexpectedResponseException("status field missing"));
      }
      if (res["status"] != "ok") {
        if (!res.containsKey("error")) {
          return Result.error(
              UnexpectedResponseException("status not ok (no error message)"));
        }
        final error = res["error"] as Map<String, dynamic>;
        final code = error["code"] as int;
        final message =
            error.containsKey("message") ? error["message"] as String : null;
        if (code == SubsonicErrorCode.incorrectCredentials.code ||
            code == SubsonicErrorCode.invalidAPIKey.code) {
          return Result.error(UnauthenticatedException());
        } else {
          return Result.error(SubsonicException(
              SubsonicErrorCode.fromCode(code), message ?? "no error message"));
        }
      }
      if (responseKey != null) {
        if (!res.containsKey(responseKey)) {
          return Result.error(UnexpectedResponseException(
              "response does not contain expected field: $responseKey"));
        }
        return Result.ok(res[responseKey]);
      }
      return Result.ok(null);
    } catch (e) {
      return Result.error(UnexpectedResponseException(e.toString()));
    }
  }

  Future<Result<http.Response>> _request(
      Uri baseUri,
      String endpointName,
      Map<String, Iterable<String>> queryParams,
      SubsonicAuth auth,
      bool post) async {
    queryParams = generateQuery(queryParams, auth);
    final queryStr = Uri(queryParameters: queryParams).query;
    {
      final sanitizedQuery = Map<String, Iterable<String>>.from(queryParams);
      if (sanitizedQuery.containsKey("p")) {
        sanitizedQuery["p"] = ["xxx"];
      }
      if (sanitizedQuery.containsKey("t")) {
        sanitizedQuery["t"] = ["xxx"];
      }
      if (sanitizedQuery.containsKey("s")) {
        sanitizedQuery["s"] = ["xxx"];
      }
      if (sanitizedQuery.containsKey("apiKey")) {
        sanitizedQuery["apiKey"] = ["xxx"];
      }
      Log.debug(
          "${post ? "POST" : "GET"} $endpointName?${Uri(queryParameters: sanitizedQuery).query}");
    }
    try {
      final response = post
          ? await http.post(Uri.parse('$baseUri/rest/$endpointName'),
              body: queryStr,
              headers: {
                  "Content-Type": "application/x-www-form-urlencoded"
                }).timeout(const Duration(seconds: 10))
          : await http
              .get(Uri.parse('$baseUri/rest/$endpointName?$queryStr'))
              .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200 && response.statusCode != 201) {
        if (response.statusCode == 401) {
          throw UnauthenticatedException();
        }
        throw ServerException(response.statusCode);
      }
      return Result.ok(response);
    } catch (e, st) {
      Log.error("Failed to connect to server", e, st);
      return Result.error(ConnectionException());
    }
  }

  Map<String, Iterable<String>> generateQuery(
      Map<String, Iterable<String>> query, SubsonicAuth auth,
      {bool constantSalt = false}) {
    final queryParams =
        constantSalt ? auth.queryParamsCacheFriendly : auth.queryParams;
    return {
      ...query,
      'c': [_clientName],
      'f': ['json'],
      'v': [_protocolVersion],
      ...queryParams.map((String key, String value) => MapEntry(key, [value])),
    };
  }

  Uri getCoverUri(Connection con, String id,
      {int? size, bool constantSalt = false}) {
    final query = generateQuery({
      "id": [id],
      "size": size != null ? [size.toString()] : [],
    }, con.auth, constantSalt: constantSalt);
    return Uri.parse(
        '${con.baseUri}/rest/getCoverArt${Uri(queryParameters: query)}');
  }
}
