import 'dart:convert';

import 'package:crossonic/data/services/opensubsonic/auth.dart';
import 'package:crossonic/data/services/opensubsonic/exceptions.dart';
import 'package:crossonic/data/services/opensubsonic/models/opensubsonic_extension_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/random_songs_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/server_info.dart';
import 'package:crossonic/data/services/opensubsonic/models/token_info_model.dart';
import 'package:crossonic/utils/exceptions.dart';
import 'package:crossonic/utils/result.dart';
import 'package:http/http.dart' as http;

class SubsonicService {
  static const String _clientName = "crossonic";
  static const String _protocolVersion = "1.16.1";

  Future<Result<RandomSongsModel>> getRandomSongs(
      Connection con, int count) async {
    return await _fetchObject(
      con,
      "getRandomSongs",
      {
        "size": [count.toString()],
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
    final result = await _request(baseUri, "ping", {}, EmptyAuth());
    switch (result) {
      case Error():
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
      case Error():
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
      case Error():
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
      final result =
          await _request(con.baseUri, endpointName, queryParams, con.auth);
      switch (result) {
        case Error():
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

  Future<Result<http.Response>> _request(Uri baseUri, String endpointName,
      Map<String, Iterable<String>> queryParams, SubsonicAuth auth) async {
    queryParams = generateQuery(queryParams, auth);
    final queryStr = Uri(queryParameters: queryParams).query;
    try {
      final response = await http.post(Uri.parse('$baseUri/rest/$endpointName'),
          body: queryStr,
          headers: {"Content-Type": "application/x-www-form-urlencoded"});
      if (response.statusCode != 200 && response.statusCode != 201) {
        if (response.statusCode == 401) {
          throw UnauthenticatedException();
        }
        throw ServerException(response.statusCode);
      }
      return Result.ok(response);
    } catch (e) {
      return Result.error(ConnectionException());
    }
  }

  Map<String, Iterable<String>> generateQuery(
      Map<String, Iterable<String>> query, SubsonicAuth auth) {
    return {
      ...query,
      'c': [_clientName],
      'f': ['json'],
      'v': [_protocolVersion],
      ...auth.queryParams
          .map((String key, String value) => MapEntry(key, [value])),
    };
  }
}
