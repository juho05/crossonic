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

enum DownloadStatus { none, enqueued, downloading, downloaded }

class SongDownloader extends ChangeNotifier {
  static const _taskGroup = "song_download";

  final db.Database _db;
  final AuthRepository _auth;
  final SubsonicService _subsonic;

  final Map<String, DownloadStatus> _downloadStatus = {};

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
    final applicationSupport = await getApplicationSupportDirectory();
    _dir = path.join(applicationSupport.path, "downloaded_songs");
    final dir = await Directory(_dir!).create(recursive: true);

    if (Platform.isAndroid) {
      applicationSupport.list().forEach((file) {
        if (path
            .basename(file.path)
            .startsWith("com.bbflight.background_downloader")) {
          file.delete();
        }
      });
    }

    await FileDownloader().trackTasksInGroup(_taskGroup);
    FileDownloader().configureNotificationForGroup(_taskGroup,
        running: TaskNotification(
            "Downloading songs",
            !kIsWeb && Platform.isIOS
                ? "Download in progress"
                : "{numFinished} out of {numTotal} songs downloaded"),
        groupNotificationId: _taskGroup);
    FileDownloader().registerCallbacks(
      group: _taskGroup,
      taskStatusCallback: _statusCallback,
    );
    _downloadStatus.addEntries(await dir
        .list()
        .map((f) => MapEntry(path.basename(f.path), DownloadStatus.downloaded))
        .toList());
    _downloadStatus.addEntries((await _db.managers.downloadTask
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
        .map((t) => MapEntry(
              t.taskId,
              t.status == TaskStatus.running.name
                  ? DownloadStatus.downloading
                  : DownloadStatus.enqueued,
            )));
    notifyListeners();
  }

  bool isDownloaded(String songId) =>
      _downloadStatus[songId] == DownloadStatus.downloaded;
  bool isDownloading(String songId) =>
      _downloadStatus[songId] == DownloadStatus.downloading;
  bool isEnqueued(String songId) =>
      _downloadStatus[songId] == DownloadStatus.enqueued;

  DownloadStatus getStatus(String songId) =>
      _downloadStatus[songId] ?? DownloadStatus.none;

  String? getPath(String songId) {
    if (kIsWeb || _dir == null) return null;
    final p = path.join(_dir!, songId);
    if (isDownloaded(songId)) return p;
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

  Future<void> _update() async {
    if (kIsWeb || _dir == null) return;
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
    await FileDownloader().cancelAll(
      tasks:
          records.where((r) => !songIds.contains(r.taskId)).map((r) => r.task),
    );

    final dir = await Directory(_dir!).create(recursive: true);

    dir.list().forEach((f) async {
      final id = path.basename(f.path);
      if (songIds.contains(id)) {
        songIds.remove(id);
        _downloadStatus[id] = DownloadStatus.downloaded;
      } else {
        File(f.path).delete();
        await FileDownloader().database.deleteRecordWithId(id);
        _downloadStatus.remove(id);
      }
    });

    for (final id in songIds.toList()) {
      final record = await FileDownloader().database.recordForId(id);
      if (record != null) {
        if (record.status.isFinalState) {
          await FileDownloader().database.deleteRecordWithId(id);
          _downloadStatus.remove(id);
        } else {
          songIds.remove(id);
        }
      }
    }

    final tasks = songIds.map((id) => DownloadTask(
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
          retries: 5,
        ));

    final result = await FileDownloader().enqueueAll(tasks.toList());
    _downloadStatus.addEntries(songIds.indexed
        .where((i) => result[i.$1] && !_downloadStatus.containsKey(i.$2))
        .map((i) => MapEntry(i.$2, DownloadStatus.enqueued)));
  }

  void _statusCallback(TaskStatusUpdate status) {
    final previousStatus = _downloadStatus[status.task.taskId];
    switch (status.status) {
      case TaskStatus.enqueued:
        _downloadStatus[status.task.taskId] = DownloadStatus.enqueued;
      case TaskStatus.running:
        _downloadStatus[status.task.taskId] = DownloadStatus.downloading;
      case TaskStatus.complete:
        _downloadStatus[status.task.taskId] = DownloadStatus.downloaded;
      case TaskStatus.notFound || TaskStatus.failed || TaskStatus.canceled:
        _downloadStatus.remove(status.task.taskId);
      case TaskStatus.waitingToRetry || TaskStatus.paused:
        _downloadStatus[status.task.taskId] = DownloadStatus.enqueued;
    }
    if (previousStatus != _downloadStatus[status.task.taskId]) {
      notifyListeners();
    }
  }

  Future<void> clear() async {
    if (kIsWeb) return;
    await FileDownloader().cancelAll(group: _taskGroup);
    await FileDownloader().database.deleteAllRecords(group: _taskGroup);
    if (_dir == null) return;
    try {
      await Directory(_dir!).delete(recursive: true);
    } catch (_) {}
    _downloadStatus.clear();
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
