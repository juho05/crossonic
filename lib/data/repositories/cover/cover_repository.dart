import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/cover/file_service.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/file.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CoverRepository extends BaseCacheManager {
  static const key = 'crossonic_cover_cache';

  final AuthRepository _authRepository;
  final SubsonicService _subsonicService;

  late final CacheManager _cacheManager;

  static String getKey(String id, int resolution) {
    return "$id\t$resolution";
  }

  CoverRepository(
      {required AuthRepository authRepository,
      required SubsonicService subsonicService})
      : _authRepository = authRepository,
        _subsonicService = subsonicService {
    _cacheManager = CacheManager(Config(
      key,
      fileService: CoverFileService(
          authRepository: _authRepository, subsonicService: _subsonicService),
      fileSystem: kIsWeb ? MemoryCacheSystem() : IOFileSystem(key),
      repo: JsonCacheInfoRepository(databaseName: key),
    ));
    _authRepository.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  Future<void> _onAuthChanged() async {
    if (!_authRepository.hasServer) {
      await clear();
    }
  }

  Future<void> clear() async {
    await _cacheManager.emptyCache();
  }

  @override
  Future<void> dispose() async {
    _authRepository.removeListener(_onAuthChanged);
    await _cacheManager.dispose();
  }

  @override
  Future<FileInfo> downloadFile(String url,
      {String? key, Map<String, String>? authHeaders, bool force = false}) {
    return _cacheManager.downloadFile(url,
        key: key, authHeaders: authHeaders, force: force);
  }

  @override
  Future<void> emptyCache() {
    return _cacheManager.emptyCache();
  }

  @override
  @Deprecated('Prefer to use the new getFileStream method')
  Stream<FileInfo> getFile(String url,
      {String? key, Map<String, String>? headers}) {
    // ignore: deprecated_member_use
    return _cacheManager.getFile(url, key: key, headers: headers);
  }

  @override
  Future<FileInfo?> getFileFromCache(String key,
      {bool ignoreMemCache = false}) {
    return _cacheManager.getFileFromCache(key, ignoreMemCache: ignoreMemCache);
  }

  @override
  Future<FileInfo?> getFileFromMemory(String key) {
    return _cacheManager.getFileFromMemory(key);
  }

  @override
  Stream<FileResponse> getFileStream(String url,
      {String? key, Map<String, String>? headers, bool withProgress = false}) {
    return _cacheManager.getFileStream(url,
        key: key, headers: headers, withProgress: withProgress);
  }

  @override
  Future<File> getSingleFile(String url,
      {String? key, Map<String, String>? headers}) {
    return _cacheManager.getSingleFile(url, key: key, headers: headers);
  }

  @override
  Future<File> putFile(String url, Uint8List fileBytes,
      {String? key,
      String? eTag,
      Duration maxAge = const Duration(days: 30),
      String fileExtension = 'file'}) {
    return _cacheManager.putFile(url, fileBytes,
        key: key, eTag: eTag, maxAge: maxAge, fileExtension: fileExtension);
  }

  @override
  Future<File> putFileStream(String url, Stream<List<int>> source,
      {String? key,
      String? eTag,
      Duration maxAge = const Duration(days: 30),
      String fileExtension = 'file'}) {
    return _cacheManager.putFileStream(url, source,
        key: key, eTag: eTag, maxAge: maxAge, fileExtension: fileExtension);
  }

  @override
  Future<void> removeFile(String key) {
    return _cacheManager.removeFile(key);
  }
}
