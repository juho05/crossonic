/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/cover/cover_image_provider.dart';
import 'package:crossonic/data/repositories/cover/cover_repository.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/data/services/database/database.dart';
import 'package:drift/native.dart';
import 'package:file/memory.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSubsonicRepository extends Mock implements SubsonicRepository {}

class TestCoverRepository extends CoverRepository {
  FileInfo? cached;
  Future<FileInfo> Function()? download;
  int downloads = 0;
  final List<String> removed = [];

  TestCoverRepository({
    required super.authRepository,
    required super.subsonicRepository,
    required super.database,
  });

  @override
  Future<FileInfo?> getFileFromCache(
    String key, {
    bool ignoreMemCache = false,
  }) async => cached;

  @override
  Future<FileInfo> downloadFile(
    String url, {
    String? key,
    Map<String, String>? authHeaders,
    bool force = false,
  }) {
    downloads++;
    return download!();
  }

  @override
  Future<void> removeFile(String key) async => removed.add(key);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fs = MemoryFileSystem();
  final key = CoverRepository.getKey("cover", 256);
  final cachedFile = fs.file("cached");
  final downloadedFile = fs.file("downloaded");

  late Database db;
  late TestCoverRepository repository;

  FileInfo info(
    FileSource source, {
    required bool expired,
    int statusCode = 200,
  }) => FileInfo(
    source == FileSource.Cache ? cachedFile : downloadedFile,
    source,
    DateTime.now().add(Duration(hours: expired ? -1 : 1)),
    key,
    statusCode: statusCode,
  );

  bool tracked(CoverImageProvider provider) =>
      PaintingBinding.instance.imageCache.statusForKey(provider).tracked;

  // leaves the provider pending in the image cache
  Future<CoverImageProvider> trackProvider() async {
    final provider = CoverImageProvider(
      repository,
      coverId: "cover",
      resolution: 256,
    );
    repository.download = () => Completer<FileInfo>().future;
    provider.resolve(ImageConfiguration.empty);
    await Future.delayed(Duration.zero);
    expect(repository.downloads, 1);
    expect(tracked(provider), isTrue);
    return provider;
  }

  Future<Completer<FileInfo>> loadExpired() async {
    final refresh = Completer<FileInfo>();
    repository.cached = info(FileSource.Cache, expired: true);
    repository.download = () => refresh.future;
    repository.downloads = 0;
    expect(await repository.loadCoverFile("cover", 256), cachedFile);
    return refresh;
  }

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel("plugins.flutter.io/path_provider"),
          (_) async => "/cache",
        );
    final auth = MockAuthRepository();
    when(() => auth.isAuthenticated).thenReturn(true);
    db = Database(NativeDatabase.memory());
    repository = TestCoverRepository(
      authRepository: auth,
      subsonicRepository: MockSubsonicRepository(),
      database: db,
    );
    await Future.delayed(Duration.zero);
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  tearDown(() async {
    await db.close();
  });

  test("downloads when nothing is cached", () async {
    repository.download = () async => info(FileSource.Online, expired: false);

    final file = await repository.loadCoverFile("cover", 256);

    expect(file, downloadedFile);
    expect(repository.downloads, 1);
  });

  test("returns a valid cached file without downloading", () async {
    repository.cached = info(FileSource.Cache, expired: false);

    final file = await repository.loadCoverFile("cover", 256);
    await Future.delayed(Duration.zero);

    expect(file, cachedFile);
    expect(repository.downloads, 0);
  });

  test(
    "returns an expired cached file without waiting for the refresh",
    () async {
      final refresh = await loadExpired();

      expect(repository.downloads, 1);
      refresh.complete(
        info(FileSource.Online, expired: false, statusCode: 304),
      );
    },
  );

  test("evicts the decoded cover when the refresh brings a new file", () async {
    final provider = await trackProvider();
    final refresh = await loadExpired();

    refresh.complete(info(FileSource.Online, expired: false));
    await Future.delayed(Duration.zero);

    expect(tracked(provider), isFalse);
  });

  test(
    "keeps the decoded cover when the server answers not modified",
    () async {
      final provider = await trackProvider();
      final refresh = await loadExpired();

      refresh.complete(
        info(FileSource.Online, expired: false, statusCode: 304),
      );
      await Future.delayed(Duration.zero);

      expect(tracked(provider), isTrue);
    },
  );

  test("keeps the cached cover when the refresh fails", () async {
    final provider = await trackProvider();
    final refresh = await loadExpired();

    refresh.completeError(Exception("offline"));
    await Future.delayed(Duration.zero);

    expect(tracked(provider), isTrue);
    expect(repository.removed, isEmpty);
  });

  test("removes the cached cover when the refresh returns 404", () async {
    final provider = await trackProvider();
    final refresh = await loadExpired();

    refresh.completeError(const HttpExceptionWithStatus(404, "not found"));
    await Future.delayed(Duration.zero);

    expect(repository.removed, [key]);
    expect(tracked(provider), isFalse);
  });
}
