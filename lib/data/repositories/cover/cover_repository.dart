import 'dart:async';
import 'dart:io' as io;
import 'dart:math';

import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/cover/web_helper.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/data/services/database/database.dart';
import 'package:drift/drift.dart';
import 'package:file/local.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/file.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class CoverRepository extends BaseCacheManager {
  final AuthRepository _auth;
  final Database _db;

  late final WebHelper _webHelper;

  static String getKey(String id, int resolution) {
    return "$id\t$resolution";
  }

  CoverRepository({
    required AuthRepository authRepository,
    required SubsonicRepository subsonicRepository,
    required Database database,
  })  : _auth = authRepository,
        _db = database {
    _webHelper = WebHelper(
      subsonic: subsonicRepository,
      db: database,
      coverRepo: this,
    );
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
    _cleanup();
  }

  Future<void> downloadCovers(List<String?> coverIds) async {
    await Future.wait(
      coverIds
          .where((id) => id != null)
          .map((id) => downloadFile(getKey(id!, 1024))),
    );
  }

  @override
  Future<FileInfo> downloadFile(String url,
      {String? key,
      Map<String, String>? authHeaders,
      bool force = false}) async {
    key = _urlToKey(url);
    final fileResponse = await _webHelper
        .downloadFile(_idFromKey(key), _sizeFromKey(key))
        .firstWhere((r) => r is FileInfo);
    _ensureCleanupScheduled();
    return fileResponse as FileInfo;
  }

  @override
  Future<void> emptyCache() async {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    final count = await _db.managers.coverCacheTable.delete();
    if (count == 0) return;
    await (await _cacheDir()).delete(recursive: true);
  }

  @override
  @Deprecated('Prefer to use the new getFileStream method')
  Stream<FileInfo> getFile(String url,
      {String? key, Map<String, String>? headers}) {
    key = _urlToKey(url);
    return getFileStream(url, key: key, withProgress: false)
        .where((r) => r is FileInfo)
        .cast<FileInfo>();
  }

  @override
  Future<FileInfo?> getFileFromCache(String key,
      {bool ignoreMemCache = false}) async {
    key = _urlToKey(key);
    final id = _idFromKey(key);
    final size = _sizeFromKey(key);
    final obj = await _db.managers.coverCacheTable
        .filter((f) => f.coverId(id) & f.size(size))
        .getSingleOrNull();
    final ready = await cacheFileIsReady(obj);
    if (!ready) {
      return null;
    }
    return FileInfo(
      await cacheFile(id, size),
      FileSource.Cache,
      obj!.validTill,
      key,
    );
  }

  @override
  Future<FileInfo?> getFileFromMemory(String key) {
    key = _urlToKey(key);
    return SynchronousFuture(null);
  }

  @override
  Stream<FileResponse> getFileStream(String url,
      {String? key, Map<String, String>? headers, bool withProgress = false}) {
    key = _urlToKey(url);
    final streamController = StreamController<FileResponse>();
    _pushFileToStream(streamController, key, withProgress);
    return streamController.stream;
  }

  @override
  Future<File> getSingleFile(String url,
      {String? key, Map<String, String>? headers}) async {
    key = _urlToKey(url);
    final cacheFile = await getFileFromCache(key);
    if (cacheFile != null && cacheFile.validTill.isAfter(DateTime.now())) {
      return cacheFile.file;
    }
    return (await downloadFile(url, key: key, authHeaders: headers)).file;
  }

  @override
  Future<File> putFile(
    String url,
    Uint8List fileBytes, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) {
    key = _urlToKey(url);
    throw UnimplementedError("not implemented");
  }

  @override
  Future<File> putFileStream(
    String url,
    Stream<List<int>> source, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) {
    key = _urlToKey(url);
    throw UnimplementedError("not implemented");
  }

  @override
  Future<void> removeFile(String key) async {
    key = _urlToKey(key);
    final id = _idFromKey(key);
    final size = _sizeFromKey(key);
    await _db.managers.coverCacheTable
        .filter((f) => f.coverId(id) & f.size(size))
        .delete();
    final file = await cacheFile(id, size);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  Future<void> invalidateCover(String coverId) async {
    await _db.managers.coverCacheTable
        .filter((f) => f.coverId(coverId))
        .delete();
    final dir = await _cacheDir();
    final filePrefix = "$coverId-";
    await dir.list(followLinks: false).forEach((entry) async {
      if (path.basename(entry.path).startsWith(filePrefix)) {
        try {
          await entry.delete();
        } catch (_) {}
      }
    });
  }

  Future<void> _pushFileToStream(
    StreamController<dynamic> streamController,
    String key,
    bool withProgress,
  ) async {
    FileInfo? cacheFile;
    try {
      cacheFile = await getFileFromCache(key);
      if (cacheFile != null) {
        streamController.add(cacheFile);
        withProgress = false;
      }
    } on Object catch (e) {
      Log.warn(
          "CacheManager: Failed to load cached file for $key with error:\n$e");
    }
    if (cacheFile == null || cacheFile.validTill.isBefore(DateTime.now())) {
      try {
        await for (final response
            in _webHelper.downloadFile(_idFromKey(key), _sizeFromKey(key))) {
          if (response is DownloadProgress && withProgress) {
            streamController.add(response);
          }
          if (response is FileInfo) {
            streamController.add(response);
          }
        }
        _ensureCleanupScheduled();
      } on Object catch (e) {
        cacheLogger.log(
            'CacheManager: Failed to download file from $key with error:\n$e',
            CacheManagerLogLevel.debug);
        if (cacheFile == null && streamController.hasListener) {
          streamController.addError(e);
        }

        if (cacheFile != null &&
            e is HttpExceptionWithStatus &&
            e.statusCode == 404) {
          if (streamController.hasListener) {
            streamController.addError(e);
          }
          await removeFile(key);
        }
      }
    }
    streamController.close();
  }

  Future<void> _onAuthChanged() async {
    if (!_auth.hasServer) {
      await emptyCache();
    }
  }

  String _urlToKey(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.pathSegments.isEmpty ||
        uri.pathSegments.last != "getCoverArt") {
      return url;
    }
    final String? id = uri.queryParameters["id"];
    final String size = uri.queryParameters["size"] ?? "512";
    if (id == null) return url;
    return "$id\t$size";
  }

  String _idFromKey(String key) {
    final parts = key.split("\t");
    if (parts.length != 2) {
      throw ArgumentError("invalid key: $key");
    }
    return parts[0];
  }

  int _sizeFromKey(String key) {
    final parts = key.split("\t");
    if (parts.length != 2) {
      throw ArgumentError("invalid key");
    }
    return int.parse(parts[1]);
  }

  Timer? _cleanupTimer;
  Future<void> _cleanup() async {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    Log.trace("Cleaning cover cache...");
    final startTime = DateTime.now();
    // delete old unfinished files
    final incompleteFiles = await _db.managers.coverCacheTable
        .filter((f) =>
            f.fileFullyWritten.isFalse() &
            f.downloadTime
                .isBefore(startTime.subtract(const Duration(hours: 1))))
        .get();
    if (incompleteFiles.isNotEmpty) {
      for (final entry in incompleteFiles) {
        final file = await cacheFile(entry.coverId, entry.size);
        try {
          await file.delete();
        } catch (_) {}
      }
      await _db.managers.coverCacheTable
          .filter((f) =>
              f.fileFullyWritten.isFalse() &
              f.downloadTime
                  .isBefore(startTime.subtract(const Duration(hours: 1))))
          .delete();
      Log.debug(
          "Deleted ${incompleteFiles.length} old incomplete cover cache files.");
    }

    int deleted = 0;
    int totalSizeKB;
    while (true) {
      totalSizeKB = (await (_db.selectOnly(_db.coverCacheTable)
                ..addColumns([_db.coverCacheTable.size.sum()]))
              .map((row) => row.read(_db.coverCacheTable.size.sum()))
              .getSingleOrNull()) ??
          0;
      if (totalSizeKB < _mBToKB(1000)) {
        if (deleted == 0) {
          Log.debug(
              "Total cover cache size: ${_formatKBSizeInMB(totalSizeKB)} MB < 1000 MB -> skipping cleanup");
        }
        break;
      }
      Log.debug("Total cover cache size: ${_formatKBSizeInMB(totalSizeKB)} MB");

      final select = _db.select(_db.coverCacheTable)
        ..join([
          leftOuterJoin(
              _db.playlistSongTable,
              _db.playlistSongTable.coverId
                  .equalsExp(_db.coverCacheTable.coverId)),
          leftOuterJoin(_db.playlistTable,
              _db.playlistTable.id.equalsExp(_db.playlistSongTable.playlistId))
        ]);
      select.where(
        (f) =>
            f.fileFullyWritten &
            f.downloadTime.isSmallerThanValue(
              startTime.subtract(
                const Duration(minutes: 10),
              ),
            ) &
            (_db.playlistSongTable.coverId.isNull() |
                _db.playlistTable.download.not()),
      );
      select.orderBy([(o) => OrderingTerm.asc(o.downloadTime)]);
      select.limit(
          max(min(((totalSizeKB - _mBToKB(1000)) / 50).round(), 10), 300));
      final oldFiles = await select.get();

      if (oldFiles.isEmpty) {
        Log.debug("No more viable cache files found to clean.");
        break;
      }

      for (final entry in oldFiles) {
        await removeFile(getKey(entry.coverId, entry.size));
      }

      deleted += oldFiles.length;
    }
    if (deleted > 0) {
      Log.debug(
          "Deleted $deleted old cover cache files. New cache size: ${_formatKBSizeInMB(totalSizeKB)} MB");
    }
  }

  void _ensureCleanupScheduled() {
    if (_cleanupTimer != null) return;
    Log.debug("Scheduling cover cache cleanup in 15 min.");
    _cleanupTimer = Timer(const Duration(minutes: 15), () => _cleanup());
  }

  int _mBToKB(int mb) {
    return mb * 1000;
  }

  String _formatKBSizeInMB(int kb) {
    return (kb / 1000).toStringAsFixed(2);
  }

  @override
  Future<void> dispose() async {
    _auth.removeListener(_onAuthChanged);
  }

  String? _cacheDirPath;
  Future<io.Directory> _cacheDir() async {
    _cacheDirPath ??=
        path.join((await getApplicationCacheDirectory()).path, "covers");
    return io.Directory(_cacheDirPath!);
  }

  Future<File> cacheFile(String id, int size) async {
    final dir = await _cacheDir();
    return const LocalFileSystem().file(path.join(dir.path, "$id-$size"));
  }

  Future<bool> cacheFileIsReady(CoverCacheTableData? obj) async {
    if (obj == null || !obj.fileFullyWritten) return false;
    return cacheFileExists(obj.coverId, obj.size);
  }

  Future<bool> cacheFileExists(String coverId, int size) async {
    File f = await cacheFile(coverId, size);
    final exists = await f.exists();
    if (!exists) {
      await _db.managers.coverCacheTable
          .filter((f) => f.coverId(coverId) & f.size(size))
          .delete();
      return false;
    }
    return true;
  }
}
