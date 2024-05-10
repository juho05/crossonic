import 'dart:convert';
import 'dart:math';

import 'package:crossonic/exceptions.dart';
import 'package:crossonic/repositories/auth/auth.dart';
import 'package:crossonic/repositories/subsonic/models/albumid3_model.dart';
import 'package:crossonic/repositories/subsonic/models/artist_model.dart';
import 'package:crossonic/repositories/subsonic/models/models.dart';
import 'package:crossonic/repositories/subsonic/models/responses/getalbumlist2_response.dart';
import 'package:crossonic/repositories/subsonic/models/responses/gettopsongs_response.dart';
import 'package:crossonic/repositories/subsonic/models/responses/search3_response.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:rxdart/rxdart.dart';

enum GetAlbumList2Type {
  random,
  newest,
  highest,
  frequent,
  recent,
  alphabeticalByName,
  alphabeticalByArtist,
  starred,
  byYear,
  byGenre
}

class SubsonicRepository {
  final AuthRepository _authRepo;
  SubsonicRepository(this._authRepo);

  final BehaviorSubject<(String, bool)> favoriteUpdates = BehaviorSubject();

  Future<Uri> getStreamURL({required String songID}) async {
    final auth = await _authRepo.auth;
    final queryParams = _generateQuery({
      'id': songID,
      'format': 'raw',
      'estimateContentLength': 'true',
    }, auth.username, auth.password);
    return Uri.parse(
        '${auth.subsonicURL}/rest/stream${Uri(queryParameters: queryParams)}');
  }

  Future<Uri> getCoverArtURL({required String coverArtID, int? size}) async {
    final auth = await _authRepo.auth;
    final queryParams = _generateQuery({
      'id': coverArtID,
      if (size != null) 'size': '$size',
    }, auth.username, auth.password,
        auth.username.substring(0, min(auth.username.length, 4)) + coverArtID);
    return Uri.parse(
        '${auth.subsonicURL}/rest/getCoverArt${Uri(queryParameters: queryParams)}');
  }

  Future<List<Media>> getRandomSongs(int size) async {
    final response = await _jsonRequest(
        "getRandomSongs",
        {
          "size": size.toString(),
        },
        GetRandomSongsResponse.fromJson,
        "randomSongs");
    final songs = response!.song ?? [];
    for (var s in songs) {
      favoriteUpdates.add((s.id, s.starred != null));
    }
    return songs;
  }

  Future<void> star({
    String? id,
    String? albumId,
    String? artistId,
  }) async {
    return _jsonRequest(
        "star",
        {
          if (id != null) "id": id,
          if (albumId != null) "albumId": albumId,
          if (artistId != null) "artistId": artistId,
        },
        null,
        null);
  }

  Future<void> unstar({
    String? id,
    String? albumId,
    String? artistId,
  }) async {
    return _jsonRequest(
        "unstar",
        {
          if (id != null) "id": id,
          if (albumId != null) "albumId": albumId,
          if (artistId != null) "artistId": artistId,
        },
        null,
        null);
  }

  Future<(List<ArtistID3>, List<AlbumID3>, List<Media>)> search3(
    String query, {
    int artistCount = 0,
    int artistOffset = 0,
    int albumCount = 0,
    int albumOffset = 0,
    int songCount = 0,
    int songOffset = 0,
    String? musicFolderId,
  }) async {
    final response = await _jsonRequest(
      "search3",
      {
        "query": query,
        "artistCount": artistCount.toString(),
        "artistOffset": artistOffset.toString(),
        "songCount": songCount.toString(),
        "songOffset": songOffset.toString(),
        if (musicFolderId != null) "musicFolderId": musicFolderId,
      },
      Search3Response.fromJson,
      "searchResult3",
    );
    final songs = response!.song ?? [];
    for (var s in songs) {
      favoriteUpdates.add((s.id, s.starred != null));
    }
    return (response.artist ?? [], response.album ?? [], songs);
  }

  Future<Artist> getArtist(String id) async {
    return (await _jsonRequest(
        "getArtist",
        {
          "id": id,
        },
        Artist.fromJson,
        "artist"))!;
  }

  Future<List<Media>> getTopSongs(String artistName, int count) async {
    final response = await _jsonRequest(
        "getTopSongs",
        {
          "artist": artistName,
          "count": count.toString(),
        },
        GetTopSongsResponse.fromJson,
        "topSongs");
    final songs = response!.song ?? [];
    for (var s in songs) {
      favoriteUpdates.add((s.id, s.starred != null));
    }
    return songs;
  }

  Future<List<AlbumID3>> getAlbumList2(
    GetAlbumList2Type type, {
    int size = 10,
    int offset = 0,
    int? fromYear,
    int? toYear,
    String? genre,
    String? musicFolderId,
  }) async {
    final response = await _jsonRequest(
        "getAlbumList2",
        {
          "type": type.name,
          "size": size.toString(),
          "offset": offset.toString(),
          if (fromYear != null) "fromYear": fromYear.toString(),
          if (toYear != null) "toYear": toYear.toString(),
          if (genre != null) "genre": genre,
          if (musicFolderId != null) "musicFolderId": musicFolderId,
        },
        AlbumList2Response.fromJson,
        "albumList2");
    return response!.album ?? [];
  }

  Future<AlbumID3> getAlbum(String id) async {
    return (await _jsonRequest(
      "getAlbum",
      {
        "id": id,
      },
      AlbumID3.fromJson,
      "album",
    ))!;
  }

  Future<T?> _jsonRequest<T>(
    String endpointName,
    Map<String, String> queryParams,
    T Function(Map<String, dynamic>)? fromJson,
    String? responseKey,
  ) async {
    final response = await _request(endpointName, queryParams);
    final json = response.headers["content-type"]?.contains("charset") ?? false
        ? response.body
        : utf8.decode(response.bodyBytes);
    Map<String, dynamic> body = jsonDecode(json);
    if (!body.containsKey("subsonic-response")) {
      throw UnexpectedServerResponseException();
    }
    final res = body["subsonic-response"] as Map<String, dynamic>;
    if (!res.containsKey("status")) {
      throw UnexpectedServerResponseException();
    }
    if (res["status"] != "ok") {
      if (!res.containsKey("error")) {
        throw UnexpectedServerResponseException();
      }
      final error = res["error"] as Map<String, dynamic>;
      final code = error["code"] as int;
      final message =
          error.containsKey("message") ? error["message"] as String : null;
      throw SubsonicException(code, message);
    }
    if (responseKey != null && fromJson != null) {
      if (!res.containsKey(responseKey)) {
        throw UnexpectedServerResponseException();
      }
      return fromJson(res[responseKey]);
    }
    return null;
  }

  Future<http.Response> _request(
      String endpointName, Map<String, String> queryParams) async {
    final auth = await _authRepo.auth;
    queryParams = _generateQuery(queryParams, auth.username, auth.password);
    try {
      final response = await http.post(
          Uri.parse('${auth.subsonicURL}/rest/$endpointName'),
          body: queryParams);
      if (response.statusCode != 200 && response.statusCode != 201) {
        if (response.statusCode == 401) {
          _authRepo.logout();
          throw UnauthenticatedException();
        }
        throw ServerException(response.statusCode);
      }
      return response;
    } catch (_) {
      throw ServerUnreachableException();
    }
  }

  Map<String, String> _generateQuery(
      Map<String, String> query, String username, String password,
      [String? salt]) {
    final (token, usedSalt) = _generateAuth(password, salt);
    return {
      ...query,
      'u': username,
      'c': 'Crossonic',
      'f': 'json',
      'v': '1.15.0',
      't': token,
      's': usedSalt,
    };
  }

  (String, String) _generateAuth(String password, [String? salt]) {
    const letters =
        "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    if (salt == null) {
      final buffer = StringBuffer();
      for (var i = 0; i < 10; i++) {
        buffer.write(letters[Random.secure().nextInt(letters.length)]);
      }
      salt = buffer.toString();
    }
    final hash = md5.convert(utf8.encode(password + salt)).toString();
    return (hash, salt);
  }
}
