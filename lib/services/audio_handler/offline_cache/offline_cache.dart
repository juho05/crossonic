import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:crossonic/repositories/api/api.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class DownloadFailedException implements Exception {}

class OfflineCache {
  final APIRepository _apiRepository;
  final Set<String> _activeTaskIDs = {};

  static const String _dirName = "offline_song_cache";

  OfflineCache({
    required APIRepository apiRepository,
  }) : _apiRepository = apiRepository;

  Future<void> download(List<Media> songs,
      {bool overwriteExisting = false}) async {
    final dir =
        path.join((await getApplicationSupportDirectory()).path, _dirName);
    await Directory(dir).create();
    final tasks = songs
        .map((s) {
          final file = File(path.join(dir, "${s.id}.ogg"));
          if (!overwriteExisting && file.existsSync()) DownloadTask(url: "");
          if (_activeTaskIDs.contains(s.id)) DownloadTask(url: "");
          return DownloadTask(
            url: _apiRepository
                .getStreamURL(songID: s.id, format: "opus", maxBitRate: 320)
                .toString(),
            allowPause: false,
            filename: "${s.id}.ogg",
            directory: _dirName,
            baseDirectory: BaseDirectory.applicationSupport,
            displayName: s.title,
            requiresWiFi: true, // TODO: make configurable
            taskId: s.id,
          );
        })
        .where((t) => t.url.isNotEmpty)
        .toList();
    if (tasks.isEmpty) return;
    final result = await FileDownloader().downloadBatch(tasks);
    print("${result.numSucceeded} - ${songs.length}");
    if (result.numSucceeded != songs.length) {
      for (var task in result.tasks) {
        final file = File(path.join(dir, "${task.taskId}.ogg"));
        file.deleteSync();
      }
      throw DownloadFailedException();
    }
  }

  Future<void> remove(Iterable<String> songIDs) async {
    final dir =
        path.join((await getApplicationSupportDirectory()).path, _dirName);
    await Directory(dir).create();
    for (var id in songIDs) {
      final file = File(path.join(dir, "$id.ogg"));
      if (!(await file.exists())) continue;
      await file.delete();
    }
  }

  Future<Set<String>> getDownloadedSongIDs() async {
    final dir = Directory(
        path.join((await getApplicationSupportDirectory()).path, _dirName));
    await dir.create();
    return await dir
        .list()
        .map((file) => path.basenameWithoutExtension(file.path))
        .toSet();
  }

  Future<Uri?> getURL(String id) async {
    if (_activeTaskIDs.contains(id)) return null;
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
