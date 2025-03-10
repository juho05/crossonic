import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/playlist/downloader_storage.dart';
import 'package:crossonic/data/services/database/database.dart' as db;
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class SongDownloader extends ChangeNotifier {
  static const _taskGroup = "song_download";

  final db.Database _db;
  final AuthRepository _auth;
  final SubsonicService _subsonic;

  final Set<String> _downloadedSongs = {};
  final Set<String> _downloadingSongs = {};

  SongDownloader({
    required db.Database db,
    required AuthRepository auth,
    required SubsonicService subsonic,
  })  : _db = db,
        _auth = auth,
        _subsonic = subsonic;

  String? _dir;

  Future<void> init() async {
    if (kIsWeb) return;
    await FileDownloader().trackTasksInGroup(_taskGroup);
    FileDownloader().registerCallbacks(
      group: _taskGroup,
      taskStatusCallback: _statusCallback,
    );
    _dir = path.join(
        (await getApplicationSupportDirectory()).path, "downloaded_songs");
    await Directory(_dir!).create(recursive: true);
    _downloadedSongs.addAll(await Directory(_dir!)
        .list()
        .map((f) => path.basename(f.path))
        .toList());
    _downloadingSongs.addAll((await _db.managers.downloadTask
            .filter(
              (f) =>
                  f.group(_taskGroup) &
                  f.type(DownloaderStorage.typeRecord) &
                  f.status.isIn([
                    TaskStatus.enqueued.name,
                    TaskStatus.running.name,
                  ]),
            )
            .get())
        .map((t) => t.taskId));
    notifyListeners();
  }

  bool isDownloaded(String songId) => _downloadedSongs.contains(songId);
  bool isDownloading(String songId) =>
      _downloadingSongs.contains(songId) && !_downloadedSongs.contains(songId);

  String? getPath(String songId) {
    if (kIsWeb || _dir == null) return null;
    final p = path.join(_dir!, songId);
    if (_downloadedSongs.contains(songId)) return p;
    return null;
  }

  Timer? _updateDebounce;
  void update([bool disableTimeout = false]) {
    if (kIsWeb) return;
    _updateDebounce?.cancel();
    if (disableTimeout) {
      _update();
      return;
    }
    _updateDebounce = Timer(const Duration(seconds: 5), _update);
  }

  bool _updating = false;

  Future<void> _update() async {
    if (kIsWeb || _updating || _dir == null) return;
    _updating = true;
    try {
      final songIds = (await (_db.select(_db.playlistSongTable).join(
        [
          innerJoin(
            _db.playlistTable,
            _db.playlistTable.id.equalsExp(_db.playlistSongTable.playlistId),
          ),
        ],
      )..where(_db.playlistTable.download.equals(true)))
              .map((t) => t.readTable(_db.playlistSongTable).songId)
              .get())
          .toSet();

      final records =
          await FileDownloader().database.allRecords(group: _taskGroup);
      for (final r in records) {
        if (!songIds.contains(r.taskId)) {
          await FileDownloader().cancel(r.task);
        }
      }

      await Directory(_dir!).list().forEach((f) async {
        final id = path.basename(f.path);
        if (songIds.contains(id)) {
          songIds.remove(id);
          _downloadedSongs.add(id);
        } else {
          File(f.path).delete();
          await FileDownloader().database.deleteRecordWithId(id);
          _downloadedSongs.remove(id);
        }
      });

      for (final id in songIds) {
        final record = await FileDownloader().database.recordForId(id);
        if (record != null) {
          if (record.status.isFinalState) {
            await FileDownloader().database.deleteRecordWithId(id);
            _downloadedSongs.remove(id);
            _downloadingSongs.remove(id);
          } else {
            continue;
          }
        }
        final success = await FileDownloader().enqueue(DownloadTask(
          group: _taskGroup,
          url: _downloadUri(id).toString(),
          httpRequestMethod: "GET",
          allowPause: true,
          baseDirectory: BaseDirectory.applicationSupport,
          directory: "downloaded_songs",
          filename: id,
          requiresWiFi: true,
          taskId: id,
          updates: Updates.status,
        ));
        if (success) {
          _downloadingSongs.add(id);
        } else {
          print("Failed to enqueue download task for $id");
        }
      }
    } finally {
      _updating = false;
    }
  }

  void _statusCallback(TaskStatusUpdate status) {
    bool changed;
    switch (status.status) {
      case TaskStatus.enqueued || TaskStatus.running:
        changed = _downloadingSongs.add(status.task.taskId);
      case TaskStatus.complete:
        changed = _downloadingSongs.remove(status.task.taskId);
        changed = _downloadedSongs.add(status.task.taskId) || changed;
      case TaskStatus.notFound || TaskStatus.failed || TaskStatus.canceled:
        changed = _downloadingSongs.remove(status.task.taskId);
      case TaskStatus.waitingToRetry || TaskStatus.paused:
        changed = _downloadingSongs.add(status.task.taskId);
    }
    if (changed) {
      notifyListeners();
    }
  }

  Future<void> clear() async {
    if (kIsWeb) return;
    await FileDownloader().cancelAll(group: _taskGroup);
    await FileDownloader().database.deleteAllRecords(group: _taskGroup);
    if (_dir == null) return;
    await Directory(_dir!).delete(recursive: true);
    _downloadedSongs.clear();
    _downloadingSongs.clear();
    notifyListeners();
  }

  Uri _downloadUri(String id) {
    final query = _subsonic.generateQuery({
      "id": [id],
    }, _auth.con.auth);
    return Uri.parse(
        '${_auth.con.baseUri}/rest/download${Uri(queryParameters: query)}');
  }
}
