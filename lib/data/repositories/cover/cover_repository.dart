import 'dart:io';

import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/cover/file_service.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CoverRepository {
  static const key = 'crossonic_cover_cache';

  final AuthRepository _authRepository;
  final SubsonicService _subsonicService;

  late final CacheManager _cacheManager;

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

  Stream<File> getFileStream(String coverId) {
    return _cacheManager
        .getFileStream(coverId, key: coverId)
        .map((f) => (f as FileInfo).file);
  }

  Future<void> clear() async {
    await _cacheManager.emptyCache();
  }

  Future<void> dispose() async {
    _authRepository.removeListener(_onAuthChanged);
    await _cacheManager.dispose();
  }
}
