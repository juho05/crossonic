import 'dart:collection';
import 'dart:io';

import 'package:crossonic/exceptions.dart';
import 'package:crossonic/repositories/api/api.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class DownloadFailedException implements Exception {}

const String _dirName = "offline_song_cache";

class OfflineCacheTask {
  final String name;
  final Iterable<String> songIDs;
  final void Function(String songID) songDownloaded;
  final void Function() done;
  final void Function(Object e) error;

  OfflineCacheTask({
    required this.name,
    required this.songIDs,
    required this.songDownloaded,
    required this.done,
    required this.error,
  });
}

class OfflineCache {
  final APIRepository _apiRepository;
  final Queue<OfflineCacheTask> _tasks = Queue();

  OfflineCache({
    required APIRepository apiRepository,
  }) : _apiRepository = apiRepository;

  void enqueue(OfflineCacheTask task) {
    _tasks.add(task);
    _download();
  }

  Future<void> _executeTask(OfflineCacheTask task) async {
    final dir =
        path.join((await getApplicationSupportDirectory()).path, _dirName);
    final client = http.Client();
    try {
      for (final id in task.songIDs) {
        final file = File(path.join(dir, "$id.ogg.tmp"));
        if (await file.exists()) {
          task.songDownloaded(id);
          continue;
        }
        await file.create(recursive: true);
        final sink = file.openWrite();
        try {
          final response = await client.send(http.Request(
              "GET",
              _apiRepository.getStreamURL(
                  songID: id, format: "opus", maxBitRate: 320)));
          if (response.statusCode != 200) {
            if (response.statusCode == 401) {
              await _apiRepository.logout();
              throw UnauthenticatedException();
            }
            throw ServerException(response.statusCode);
          }
          await response.stream.pipe(sink);
          await sink.close();
          await file.rename(path.join(dir, "$id.ogg"));
          task.songDownloaded(id);
        } catch (e) {
          await sink.close();
          rethrow;
        }
      }
      task.done();
    } catch (e) {
      task.error(e);
    } finally {
      client.close();
    }
  }

  bool _running = false;
  Future<void> _download() async {
    if (_running) return;
    _running = true;
    await _cleanTmpFiles();
    try {
      while (true) {
        if (_tasks.isEmpty) break;
        final task = _tasks.removeFirst();
        try {
          await _executeTask(task);
        } catch (e) {
          print("Failed to execute download task ${task.name}: $e");
        }
      }
    } catch (e) {
      await _cleanTmpFiles();
      rethrow;
    } finally {
      _running = false;
    }
  }

  Future<void> remove(Iterable<String> songIDs) async {
    if (songIDs.isEmpty) return;
    final dir =
        path.join((await getApplicationSupportDirectory()).path, _dirName);
    await Directory(dir).create();
    for (var id in songIDs) {
      final file = File(path.join(dir, "$id.ogg"));
      if (!(await file.exists())) continue;
      await file.delete();
    }
  }

  Future<void> _cleanTmpFiles() async {
    if (kIsWeb) return;
    final dir = Directory(
        path.join((await getApplicationSupportDirectory()).path, _dirName));
    await dir.create();
    await dir.list().forEach((file) async {
      if (path.extension(file.path) == ".tmp") {
        await file.delete();
      }
    });
  }

  Future<Set<String>> getDownloadedSongIDs() async {
    if (kIsWeb) return {};
    final dir = Directory(
        path.join((await getApplicationSupportDirectory()).path, _dirName));
    await dir.create();
    return await dir
        .list()
        .map((file) => path.basenameWithoutExtension(file.path))
        .toSet();
  }

  Future<Uri?> getURL(String id) async {
    if (kIsWeb) return null;
    final dir =
        path.join((await getApplicationSupportDirectory()).path, _dirName);
    await Directory(dir).create();
    final file = File(path.join(dir, "$id.ogg"));
    if (file.existsSync()) {
      return file.uri;
    }
    return null;
  }
}
