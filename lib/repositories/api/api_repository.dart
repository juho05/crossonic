import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crossonic/exceptions.dart';
import 'package:crossonic/repositories/api/models/albumid3_model.dart';
import 'package:crossonic/repositories/api/models/artist_model.dart';
import 'package:crossonic/repositories/api/models/listenbrainz_model.dart';
import 'package:crossonic/repositories/api/models/models.dart';
import 'package:crossonic/repositories/api/models/responses/getalbumlist2_response.dart';
import 'package:crossonic/repositories/api/models/responses/getlyricsbysongid_response.dart';
import 'package:crossonic/repositories/api/models/responses/gettopsongs_response.dart';
import 'package:crossonic/repositories/api/models/responses/search3_response.dart';
import 'package:crossonic/repositories/api/models/scan_status_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

enum AuthStatus { authenticated, unauthenticated }

class Artists extends Equatable {
  final Iterable<ArtistIDName> artists;
  final String displayName;

  const Artists({required this.artists, required this.displayName});

  @override
  List<Object> get props => [artists, displayName];
}

class ArtistIDName extends Equatable {
  final String id;
  final String name;

  const ArtistIDName({required this.id, required this.name});

  @override
  List<Object> get props => [id, name];
}

class ScrobbleData extends Equatable {
  final String id;
  final int timeUnixMS;
  final int durationMS;

  const ScrobbleData({
    required this.id,
    required this.timeUnixMS,
    required this.durationMS,
  });

  @override
  List<Object?> get props => [id, timeUnixMS, durationMS];
}

class APIRepository {
  APIRepository._({
    String? serverURL,
    String? username,
    String? password,
  })  : _serverURL = serverURL ?? "",
        _username = username ?? "",
        _password = password ?? "";

  static const _storage = FlutterSecureStorage();

  static Future<APIRepository> init() async {
    final serverURL = await _storage.read(key: "crossonic_auth_server_url");
    final username = await _storage.read(key: "crossonic_auth_username");
    final password = await _storage.read(key: "crossonic_auth_password");
    final apiRepository = APIRepository._(
      serverURL: serverURL,
      username: username,
      password: password,
    );
    bool authenticated =
        serverURL != null && username != null && password != null;
    try {
      if (!authenticated) {
        apiRepository.authStatus.add(AuthStatus.unauthenticated);
      } else {
        try {
          await apiRepository.login(serverURL, username, password);
          apiRepository.authStatus.add(AuthStatus.authenticated);
        } on ServerUnreachableException {
          apiRepository.authStatus.add(AuthStatus.authenticated);
        }
      }
    } catch (_) {
      apiRepository.authStatus.add(AuthStatus.unauthenticated);
    }
    return apiRepository;
  }

  final BehaviorSubject<(String, bool)> favoriteUpdates = BehaviorSubject();

  String _serverURL = "";
  String get serverURL => _serverURL;
  String _username = "";
  String get username => _username;
  String _password = "";

  Future<ListenBrainzConfig> connectListenBrainz(String token) async {
    final response = await _jsonRequest(
        "crossonic/connectListenBrainz",
        {
          "token": [token],
        },
        ListenBrainzConfig.fromJson,
        "listenBrainzConfig");
    return response!;
  }

  Future<ListenBrainzConfig> getListenBrainzConfig() async {
    final response = await _jsonRequest("crossonic/getListenBrainzConfig", {},
        ListenBrainzConfig.fromJson, "listenBrainzConfig");
    return response!;
  }

  Future<void> submitScrobbles(Iterable<ScrobbleData> scrobbles) async {
    return _jsonRequest(
        "scrobble",
        {
          'id': scrobbles.map((s) => s.id),
          'time': scrobbles.map((s) => s.timeUnixMS.toString()),
          'duration_ms': scrobbles.map((s) => s.durationMS.toString()),
          'submission': ['true'],
        },
        null,
        null);
  }

  Future<void> sendNowPlaying(String id) async {
    return _jsonRequest(
        "scrobble",
        {
          'id': [id],
          'submission': ['false'],
        },
        null,
        null);
  }

  Future<ScanStatus> getScanStatus() async {
    final status = await _jsonRequest(
        "getScanStatus", {}, ScanStatus.fromJson, "scanStatus");
    return status!;
  }

  Future<ScanStatus> startScan() async {
    final status =
        await _jsonRequest("startScan", {}, ScanStatus.fromJson, "scanStatus");
    return status!;
  }

  Future<GetLyricsBySongIdResponse> getLyricsBySongId(String songID) async {
    final response = await _jsonRequest(
        "getLyricsBySongId",
        {
          "id": [songID]
        },
        GetLyricsBySongIdResponse.fromJson,
        "lyricsList");
    return response!;
  }

  Future<Uri> getStreamURL(
      {required String songID,
      String? format,
      int? maxBitRate,
      int? timeOffset}) async {
    final queryParams = _generateQuery({
      'id': [songID],
      if (format != null) 'format': [format],
      if (maxBitRate != null) 'maxBitRate': [maxBitRate.toString()],
      if (timeOffset != null) 'timeOffset': [timeOffset.toString()]
    });
    return Uri.parse(
        '$_serverURL/rest/stream${Uri(queryParameters: queryParams)}');
  }

  Future<Uri> getCoverArtURL({required String coverArtID, int? size}) async {
    final queryParams = _generateQuery({
      'id': [coverArtID],
      if (size != null) 'size': ['$size'],
    }, _username.substring(0, min(_username.length, 4)) + coverArtID);
    return Uri.parse(
        '$_serverURL/rest/getCoverArt${Uri(queryParameters: queryParams)}');
  }

  Future<List<Media>> getRandomSongs(int size) async {
    final response = await _jsonRequest(
        "getRandomSongs",
        {
          "size": [size.toString()],
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
          if (id != null) "id": [id],
          if (albumId != null) "albumId": [albumId],
          if (artistId != null) "artistId": [artistId],
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
          if (id != null) "id": [id],
          if (albumId != null) "albumId": [albumId],
          if (artistId != null) "artistId": [artistId],
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
        "query": [query],
        "artistCount": [artistCount.toString()],
        "artistOffset": [artistOffset.toString()],
        "songCount": [songCount.toString()],
        "songOffset": [songOffset.toString()],
        if (musicFolderId != null) "musicFolderId": [musicFolderId],
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
          "id": [id],
        },
        Artist.fromJson,
        "artist"))!;
  }

  Future<List<Media>> getTopSongs(String artistName, int count) async {
    final response = await _jsonRequest(
        "getTopSongs",
        {
          "artist": [artistName],
          "count": [count.toString()],
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
          "type": [type.name],
          "size": [size.toString()],
          "offset": [offset.toString()],
          if (fromYear != null) "fromYear": [fromYear.toString()],
          if (toYear != null) "toYear": [toYear.toString()],
          if (genre != null) "genre": [genre],
          if (musicFolderId != null) "musicFolderId": [musicFolderId],
        },
        AlbumList2Response.fromJson,
        "albumList2");
    return response!.album ?? [];
  }

  Future<AlbumID3> getAlbum(String id) async {
    final albums = (await _jsonRequest(
      "getAlbum",
      {
        "id": [id],
      },
      AlbumID3.fromJson,
      "album",
    ))!;
    return albums;
  }

  static Artists getArtistsOfSong(Media song) {
    Iterable<ArtistIDName> artists;
    if (song.artists == null || song.artists!.isEmpty) {
      artists = [
        if (song.artist != null && song.artistId != null)
          ArtistIDName(id: song.artistId!, name: song.artist!),
      ];
    } else {
      artists = song.artists!.map((a) => ArtistIDName(id: a.id, name: a.name));
    }

    String displayArtist;
    if (artists.isEmpty) {
      displayArtist = "Unknown artist";
    } else if (song.displayArtist != null &&
        song.displayArtist != song.artist) {
      displayArtist = song.displayArtist!;
    } else {
      displayArtist = artists.map((a) => a.name).join(", ");
    }
    return Artists(artists: artists, displayName: displayArtist);
  }

  static Artists getArtistsOfAlbum(AlbumID3 album) {
    Iterable<ArtistIDName> artists;
    if (album.artists == null || album.artists!.isEmpty) {
      artists = [
        if (album.artist != null && album.artistId != null)
          ArtistIDName(id: album.artistId!, name: album.artist!),
      ];
    } else {
      artists = album.artists!.map((a) => ArtistIDName(id: a.id, name: a.name));
    }

    String displayArtist;
    if (artists.isEmpty) {
      displayArtist = "Unknown artist";
    } else if (album.displayArtist != null &&
        album.displayArtist != album.artist) {
      displayArtist = album.displayArtist!;
    } else {
      displayArtist = artists.map((a) => a.name).join(", ");
    }
    return Artists(artists: artists, displayName: displayArtist);
  }

  Future<T?> _jsonRequest<T>(
    String endpointName,
    Map<String, Iterable<String>> queryParams,
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
    if (!res.containsKey("crossonic") || !(res["crossonic"] as bool)) {
      throw NotACrossonicServerException();
    }
    if (res["status"] != "ok") {
      if (!res.containsKey("error")) {
        throw UnexpectedServerResponseException();
      }
      final error = res["error"] as Map<String, dynamic>;
      final code = error["code"] as int;
      final message =
          error.containsKey("message") ? error["message"] as String : null;
      if (code == 40) {
        logout();
        throw UnauthenticatedException();
      } else {
        throw SubsonicException(code, message);
      }
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
      String endpointName, Map<String, Iterable<String>> queryParams) async {
    queryParams = _generateQuery(queryParams);
    final queryStr = Uri(queryParameters: queryParams).query;
    try {
      final response = await http
          .post(Uri.parse('$_serverURL/rest/$endpointName'), body: queryStr);
      if (response.statusCode != 200 && response.statusCode != 201) {
        if (response.statusCode == 401) {
          logout();
          throw UnauthenticatedException();
        }
        throw ServerException(response.statusCode);
      }
      return response;
    } catch (e) {
      print(e);
      throw ServerUnreachableException();
    }
  }

  Map<String, Iterable<String>> _generateQuery(
      Map<String, Iterable<String>> query,
      [String? salt]) {
    final (token, usedSalt) = _generateAuth(_password, salt);
    return {
      ...query,
      'u': [_username],
      'c': ['Crossonic'],
      'f': ['json'],
      'v': ['1.16.1'],
      't': [token],
      's': [usedSalt],
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

  Future<void> login(String serverURL, String username, String password) async {
    var wasSignedIn =
        _serverURL.isNotEmpty && _username.isNotEmpty && _password.isNotEmpty;
    if (wasSignedIn &&
        (_serverURL != serverURL ||
            _username != username ||
            _password != password)) {
      logout();
      wasSignedIn = false;
    }
    _serverURL = serverURL;
    _username = username;
    _password = password;
    await _jsonRequest("ping", {}, null, "");
    if (!wasSignedIn) {
      authStatus.add(AuthStatus.authenticated);
    }
    await _storeAuthState();
  }

  Future<void> logout() async {
    if (authStatus.value != AuthStatus.unauthenticated) {
      for (var cb in _beforeLogoutCallbacks) {
        await cb();
      }
      authStatus.add(AuthStatus.unauthenticated);
    }
    _username = "";
    _password = "";
    _serverURL = "";
    _storeAuthState();
  }

  final BehaviorSubject<AuthStatus> authStatus = BehaviorSubject();
  final List<Future<void> Function()> _beforeLogoutCallbacks = [];

  void addBeforeLogoutCallback(Future<void> Function() cb) {
    _beforeLogoutCallbacks.add(cb);
  }

  Future<void> _storeAuthState() async {
    await _storage.write(key: "crossonic_auth_server_url", value: _serverURL);
    await _storage.write(key: "crossonic_auth_username", value: _username);
    await _storage.write(key: "crossonic_auth_password", value: _password);
  }

  void dispose() => authStatus.close();
}
