import 'dart:async';
import 'dart:collection';
import 'dart:io' as io;
import 'dart:isolate';

import 'package:crossonic/data/repositories/cover/cover_repository.dart';
import 'package:crossonic/data/repositories/cover/not_found_response.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/data/services/database/database.dart';
import 'package:drift/drift.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart';
import 'package:rxdart/rxdart.dart';

class WebHelper {
  static const int concurrentFetches = 10;
  static const statusCodesNewFile = [io.HttpStatus.ok, io.HttpStatus.accepted];
  static const statusCodesFileNotChanged = [io.HttpStatus.notModified];

  final CoverRepository _coverRepo;
  final Database _db;
  final SubsonicRepository _subsonic;
  final Map<String, BehaviorSubject<FileResponse>> _memCache;
  final Queue<(String, int)> _queue = Queue();
  final http.Client _http = http.Client();

  WebHelper({
    required CoverRepository coverRepo,
    required Database db,
    required SubsonicRepository subsonic,
  })  : _coverRepo = coverRepo,
        _db = db,
        _subsonic = subsonic,
        _memCache = {};

  ///Download the file from the url
  Stream<FileResponse> downloadFile(String coverId, int size,
      {bool ignoreMemCache = false}) {
    final key = CoverRepository.getKey(coverId, size);
    var subject = _memCache[key];
    if (subject == null || ignoreMemCache) {
      subject = BehaviorSubject<FileResponse>();
      _memCache[key] = subject;
      _downloadOrAddToQueue(coverId, size);
    }
    return subject.stream;
  }

  var concurrentCalls = 0;

  Future<void> _downloadOrAddToQueue(String coverId, int size) async {
    final key = CoverRepository.getKey(coverId, size);
    //Add to queue if there are too many calls.
    if (concurrentCalls >= concurrentFetches) {
      _queue.add((coverId, size));
      return;
    }
    Log.trace("CacheManager: Downloading cover for $coverId size $size");

    concurrentCalls++;
    final subject = _memCache[key]!;
    try {
      await for (final result in _updateFile(coverId, size)) {
        subject.add(result);
      }
    } on Object catch (e, stackTrace) {
      subject.addError(e, stackTrace);
    } finally {
      concurrentCalls--;
      await subject.close();
      _memCache.remove(key);
      _checkQueue();
    }
  }

  void _checkQueue() {
    if (_queue.isEmpty) return;
    final next = _queue.removeFirst();
    _downloadOrAddToQueue(next.$1, next.$2);
  }

  ///Download the file from the url
  Stream<FileResponse> _updateFile(String coverId, int size) async* {
    DateTime? lastDownload;
    if (await _coverRepo.cacheFileExists(coverId, size)) {
      final cacheObj = await _db.managers.coverCacheTable
          .filter((f) => f.coverId(coverId) & f.size(size))
          .getSingleOrNull();
      lastDownload = cacheObj?.downloadTime;
    } else {
      final largerCacheObj = await _db.managers.coverCacheTable
          .filter((f) => f.coverId(coverId) & f.size.isBiggerThan(size))
          .orderBy((o) => o.size.asc())
          .limit(1)
          .getSingleOrNull();
      if (largerCacheObj != null) {
        final response = await _resizeExistingCover(largerCacheObj.coverId,
            largerCacheObj.size, largerCacheObj.validTill, size);
        if (response != null) {
          yield response;
          if (largerCacheObj.validTill.isAfter(DateTime.now())) {
            return;
          }
        }
      }
    }
    final uri = _subsonic.getCoverUri(coverId, size: size);
    final response = await _download(uri, lastDownload: lastDownload);
    yield* _manageResponse(coverId, size, uri, response);
  }

  Future<FileResponse?> _resizeExistingCover(
      String coverId, int size, DateTime validTill, int targetSize) async {
    final file = await _coverRepo.cacheFile(coverId, size);
    if (!await file.exists()) return null;

    final newImage = await Isolate.run<Uint8List?>(() async {
      final fileContent = await file.readAsBytes();
      Decoder? decoder = findDecoderForData(fileContent);
      if (decoder == null) {
        Log.warn(
            "Failed to determine decoder to downsize existing cover image: ${file.path}");
        return null;
      }
      Image? image = decoder.decode(fileContent);
      if (image == null) {
        Log.warn("Failed to decode existing cover image: ${file.path}");
        return null;
      }
      Image newImage;
      if (image.width > image.height) {
        newImage = resize(image,
            height: targetSize,
            width: targetSize * (image.width / image.height).round());
      } else {
        newImage = resize(image,
            width: targetSize,
            height: targetSize * (image.height / image.width).round());
      }
      return encodeJpg(newImage, quality: 85);
    });
    if (newImage == null) return null;

    var newFile = await _coverRepo.cacheFile(coverId, targetSize);
    newFile = await newFile.writeAsBytes(newImage);
    return FileInfo(newFile, FileSource.Cache, validTill,
        CoverRepository.getKey(coverId, targetSize));
  }

  Future<FileServiceResponse> _download(
    Uri uri, {
    DateTime? lastDownload,
  }) async {
    final headers = <String, String>{};

    if (lastDownload != null) {
      headers[io.HttpHeaders.ifModifiedSinceHeader] =
          io.HttpDate.format(lastDownload);
    }

    final req = http.Request("GET", uri);
    req.headers.addAll(headers);
    final httpResponse = await _http.send(req);
    if (statusCodesNewFile.contains(httpResponse.statusCode)) {
      if (httpResponse.headers["content-type"]?.startsWith("application/") ??
          false) {
        return NotFoundResponse();
      }
    }
    return HttpGetResponse(httpResponse);
  }

  Stream<FileResponse> _manageResponse(
      String coverId, int size, Uri uri, FileServiceResponse response) async* {
    final hasNewFile = statusCodesNewFile.contains(response.statusCode);
    final keepOldFile = statusCodesFileNotChanged.contains(response.statusCode);
    if (!hasNewFile && !keepOldFile) {
      throw HttpExceptionWithStatus(
        response.statusCode,
        'Invalid statusCode: ${response.statusCode}',
        uri: uri,
      );
    }

    if (hasNewFile) {
      await for (final progress in _saveFile(coverId, size, response)) {
        yield DownloadProgress(CoverRepository.getKey(coverId, size),
            response.contentLength, progress);
      }
    }

    if (keepOldFile) {
      await _db.managers.coverCacheTable.update((o) => o(
          validTill: Value(response.validTill),
          downloadTime: Value(DateTime.now())));
    }

    yield FileInfo(
      await _coverRepo.cacheFile(coverId, size),
      FileSource.Online,
      response.validTill,
      CoverRepository.getKey(coverId, size),
      statusCode: response.statusCode,
    );
  }

  Stream<int> _saveFile(
      String coverId, int size, FileServiceResponse response) {
    final receivedBytesResultController = StreamController<int>();
    _saveFileAndPostUpdates(
      coverId,
      size,
      receivedBytesResultController,
      response,
    );
    return receivedBytesResultController.stream;
  }

  Future<void> _saveFileAndPostUpdates(
    String coverId,
    int size,
    StreamController<int> receivedBytesResultController,
    FileServiceResponse response,
  ) async {
    final file = await _coverRepo.cacheFile(coverId, size);
    await file.create(recursive: true);

    await _db.managers.coverCacheTable.create(
      (o) => o(
        coverId: coverId,
        size: size,
        downloadTime: DateTime.now(),
        fileFullyWritten: false,
        validTill: response.validTill,
        fileSizeKB: ((response.contentLength ?? 0) / 1000).floor(),
      ),
      onConflict: DoUpdate(
        (old) => CoverCacheTableCompanion(
          downloadTime: Value(DateTime.now()),
          fileFullyWritten: const Value(false),
          validTill: Value(response.validTill),
          fileSizeKB: Value(((response.contentLength ?? 0) / 1000).floor()),
        ),
      ),
    );

    bool success = false;
    var receivedBytes = 0;
    try {
      final sink = file.openWrite();
      await response.content.map((s) {
        receivedBytes += s.length;
        receivedBytesResultController.add(receivedBytes);
        return s;
      }).pipe(sink);
      success = true;
    } on Object catch (e, stacktrace) {
      receivedBytesResultController.addError(e, stacktrace);
      await _db.managers.coverCacheTable
          .filter((f) => f.coverId(coverId) & f.size(size))
          .delete();
    }
    await receivedBytesResultController.close();
    if (success) {
      await _db.managers.coverCacheTable
          .filter((f) => f.coverId(coverId) & f.size(size))
          .update((o) => o(
              fileFullyWritten: const Value(true),
              fileSizeKB: Value((receivedBytes / 1000).floor())));
    }
  }
}
