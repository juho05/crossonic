import 'dart:convert';
import 'dart:math';

import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/version/version.dart';
import 'package:crossonic/data/repositories/version/version_repository.dart';
import 'package:crossonic/data/services/github/exceptions.dart';
import 'package:crossonic/data/services/github/models/tag.dart';
import 'package:crossonic/utils/result.dart';
import 'package:http/http.dart' as http;

class GitHubService {
  final http.Client _httpClient = http.Client();

  final Uri _apiBaseUri;
  final Uri _webBaseUri;

  GitHubService(
      {String apiBaseUri = "https://api.github.com",
      String webBaseUri = "https://github.com"})
      : _apiBaseUri = Uri.parse(apiBaseUri),
        _webBaseUri = Uri.parse("https://github.com");

  Future<Result<Iterable<GitHubTag>?>> getRepositoryTags(
      {required String owner,
      required String repo,
      int? pageSize,
      int? page}) async {
    return _fetchList<GitHubTag>(
      "GET",
      "/repos/${Uri.encodeComponent(owner)}/${Uri.encodeComponent(repo)}/tags",
      GitHubTag.fromJson,
      queryParameters: {
        if (pageSize != null) "per_page": [pageSize.toString()],
        "page": [page.toString()],
      },
    );
  }

  Future<Result<Iterable<T>?>> _fetchList<T>(
    String method,
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, List<String>> queryParameters = const {},
    Map<String, String> headers = const {},
  }) async {
    final result = await _request(method, path,
        queryParameters: queryParameters, headers: headers);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok<String?>():
        if (result.value == null) return const Result.ok(null);
        final list = jsonDecode(result.value!) as List<dynamic>;
        return Result.ok(
            list.map((dynamic obj) => fromJson(obj as Map<String, dynamic>)));
    }
  }

  // ignore: unused_element
  Future<Result<T?>> _fetchObject<T>(
    String method,
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, List<String>> queryParameters = const {},
    Map<String, String> headers = const {},
  }) async {
    final result = await _request(method, path,
        queryParameters: queryParameters, headers: headers);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok<String?>():
        if (result.value == null) return Result.ok(null);
        return Result.ok(fromJson(jsonDecode(result.value!)));
    }
  }

  Version? _currentVersion;
  Future<Result<String?>> _request(
    String method,
    String path, {
    Map<String, List<String>> queryParameters = const {},
    Map<String, String> headers = const {},
  }) async {
    final req = http.Request(
        method,
        _apiBaseUri.resolveUri(Uri(
          path: path,
          queryParameters: queryParameters,
        )));
    _currentVersion ??= await VersionRepository.getCurrentVersion();
    req.headers.addAll({
      "Accept": "application/vnd.github+json",
      // https://docs.github.com/en/rest/about-the-rest-api/api-versions?apiVersion=2022-11-28#supported-api-versions
      "X-GitHub-Api-Version": "2022-11-28",
      "User-Agent": "Crossonic v$_currentVersion",
    });
    req.headers.addAll(headers);
    int maxRetries = 5;
    try {
      http.StreamedResponse response;
      do {
        maxRetries--;
        Log.trace("GitHub request: ${req.method} ${req.url}");
        response = await _httpClient.send(req);
        if (response.statusCode == 429 ||
            (response.statusCode == 403 &&
                response.headers["x-ratelimit-remaining"] == "0")) {
          Log.debug("GitHub rate limit exceeded");
          if (maxRetries == 0) {
            throw GitHubRateLimitMaxRetriesExceeded();
          }
          int? reset =
              int.tryParse(response.headers["x-ratelimit-reset"] ?? "");
          if (reset == null) {
            Log.warn(
                "GitHub invalid x-ratelimit-reset header: ${response.headers["x-ratelimit-reset"]}");
            reset = 60;
          }
          final delay =
              min(0, reset * 1000 - DateTime.now().millisecondsSinceEpoch) + 1;
          Log.debug("Retrying GitHub request in $delay seconds");
          await Future.delayed(Duration(seconds: delay));
          continue;
        }
        if (response.statusCode == 304) {
          return const Result.ok(null);
        }
        if (response.statusCode >= 300) {
          throw GitHubUnexpectedStatusCode(response.statusCode);
        }
        break;
      } while (maxRetries > 0);
      return Result.ok(await response.stream.bytesToString());
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Uri generateReleaseDownloadLink(String downloadFileName, String tag) {
    return _webBaseUri.resolveUri(Uri(pathSegments: [
      "juho05",
      "crossonic",
      "releases",
      "download",
      tag,
      downloadFileName
    ]));
  }
}
