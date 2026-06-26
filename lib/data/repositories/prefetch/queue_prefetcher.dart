/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crossonic/data/repositories/audio/players/local_song_source.dart';
import 'package:crossonic/data/repositories/audio/queue/queue_manager.dart';
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
import 'package:crossonic/data/repositories/settings/prefetch.dart';
import 'package:crossonic/data/repositories/settings/transcoding.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

class _PrefetchException implements Exception {
  final String message;

  _PrefetchException(this.message);

  @override
  String toString() => "PrefetchException: $message";
}

class _PrefetchTask {
  final Song song;
  final String transcodeTag;

  bool canceled = false;
  int received = 0;
  bool canResume = false;
  void Function()? abort;

  _PrefetchTask({required this.song, required this.transcodeTag});
}

class QueuePrefetcher extends ChangeNotifier implements LocalSongSource {
  static const Duration _stallTimeout = Duration(seconds: 20);
  static const Duration _connectTimeout = Duration(seconds: 15);

  final AuthRepository _auth;
  final SubsonicService _subsonic;
  final SongDownloader _songDownloader;
  final QueueManager _queue;
  final PrefetchSettings _settings;
  final TranscodingSettings _transcoding;

  final http.Client _client = http.Client();
  final Random _rand = Random();

  final StreamController<Song> _songCachedController =
      StreamController.broadcast();

  Stream<Song> get songCached => _songCachedController.stream;

  final StreamController<String> _songRemovedFromCacheController =
      StreamController.broadcast();

  Stream<String> get songRemovedFromCache =>
      _songRemovedFromCacheController.stream;

  final BehaviorSubject<String?> _currentDownloadSongId =
      BehaviorSubject.seeded(null);

  ValueStream<String?> get currentDownloadSongId =>
      _currentDownloadSongId.stream;

  String? _dir;

  bool _throttled = false;
  bool _enabledByPlayer = true;
  bool _wasEnabledInSettings = false;

  String? _format;
  int? _maxBitRate;

  List<Song> _prioWindow = [];
  List<Song> _regularWindow = [];

  // song id -> transcode tag of the completed cache file
  final Map<String, String> _cached = {};

  // song id -> in-flight download task
  final Map<String, _PrefetchTask> _tasks = {};

  // song id -> transcode tag of a kept, resumable .part file that a future
  // task can continue from instead of restarting (survives throttling and
  // other transient cancellations)
  final Map<String, String> _partial = {};

  QueuePrefetcher({
    required this._auth,
    required this._subsonic,
    required this._songDownloader,
    required this._queue,
    required this._settings,
    required this._transcoding,
  }) {
    _wasEnabledInSettings = _settings.enabled;
    _queue.addListener(_scheduleWindowUpdate);
    _settings.addListener(_onSettingsChanged);
    _transcoding.addListener(_updateTranscoding);
    _auth.addListener(_onAuthChanged);
  }

  Future<void> init() async {
    if (kIsWeb) return;
    final appCacheDir = await getApplicationCacheDirectory();
    _dir = path.join(appCacheDir.path, "prefetch");
    await clear();
    await _updateTranscoding();
    _scheduleWindowUpdate();
  }

  String get _currentProfileTag =>
      "${_format ?? 'default'}-${_maxBitRate ?? 0}";

  bool get _canDownload =>
      !kIsWeb &&
      _settings.enabled &&
      _enabledByPlayer &&
      !_throttled &&
      _auth.isAuthenticated &&
      _dir != null;

  @override
  bool isDownloaded(String id) => !kIsWeb && _cached[id] == _currentProfileTag;

  @override
  String? getPath(String id) {
    if (kIsWeb || _dir == null) return null;
    if (_cached[id] != _currentProfileTag) return null;
    final path = _finalPath(id, _currentProfileTag);
    if (!File(path).existsSync()) {
      _cached.remove(id);
      return null;
    }
    return path;
  }

  void enable() {
    if (_enabledByPlayer) return;
    _enabledByPlayer = true;
    _scheduleReconcile();
  }

  void disable() {
    if (!_enabledByPlayer) return;
    _enabledByPlayer = false;
    _cancelAllTasks();
  }

  void setThrottled(bool throttled) {
    if (_throttled == throttled) return;
    _throttled = throttled;
    if (throttled) {
      _cancelAllTasks();
    } else {
      _scheduleReconcile();
    }
  }

  void _onSettingsChanged() {
    if (_wasEnabledInSettings && !_settings.enabled) {
      _wasEnabledInSettings = false;
      clear();
      return;
    }
    _wasEnabledInSettings = _settings.enabled;
    _scheduleWindowUpdate();
    _scheduleReconcile();
  }

  void _onAuthChanged() {
    if (_auth.isAuthenticated) {
      _updateTranscoding();
      _scheduleWindowUpdate();
    } else {
      _prioWindow = [];
      _regularWindow = [];
      clear();
    }
  }

  Future<void> _updateTranscoding() async {
    final (codec, bitRate) = await _transcoding.activeTranscoding();
    final format = codec != TranscodingCodec.serverDefault ? codec.name : null;
    final maxBitRate = codec != TranscodingCodec.raw ? bitRate : null;
    if (_format == format && _maxBitRate == maxBitRate) return;
    _format = format;
    _maxBitRate = maxBitRate;
    notifyListeners();
    _scheduleReconcile();
  }

  Timer? _windowDebounce;

  void _scheduleWindowUpdate() {
    if (kIsWeb) return;
    _windowDebounce?.cancel();
    _windowDebounce = Timer(const Duration(milliseconds: 400), _updateWindow);
  }

  Future<void> _updateWindow() async {
    if (!_auth.isAuthenticated) {
      _prioWindow = [];
      _regularWindow = [];
      _scheduleReconcile();
      return;
    }
    final count = _settings.count;
    final priority = (await _queue.getPrioritySongs(limit: count)).toList();
    final remaining = count - priority.length;
    var regular = <Song>[];
    if (remaining > 0) {
      final offset = _queue.currentIndex + 1;
      if (offset >= 0) {
        regular = (await _queue.getRegularSongs(
          limit: remaining,
          offset: offset,
        )).toList();
      }
    }
    _prioWindow = priority;
    _regularWindow = regular;
    _scheduleReconcile();
  }

  Future<void> clear() async {
    _cancelAllTasks();

    final currentId = _queue.current.value?.id;

    for (final id in _cached.keys.toList()) {
      if (id == currentId) continue;
      _cached.remove(id);
      _songRemovedFromCacheController.add(id);
    }
    _partial.clear();

    if (_dir != null) {
      try {
        await for (final entry in Directory(_dir!).list()) {
          if (currentId != null &&
              path.basename(entry.path).startsWith("$currentId-")) {
            continue;
          }
          try {
            await entry.delete(recursive: true);
          } catch (_) {}
        }
      } catch (_) {}
    }

    notifyListeners();
  }

  Timer? _reconcileDebounce;

  void _scheduleReconcile() {
    if (kIsWeb) return;
    _reconcileDebounce?.cancel();
    _reconcileDebounce = Timer(const Duration(milliseconds: 300), _reconcile);
  }

  void _reconcile() {
    if (kIsWeb || _dir == null) return;

    if (!_canDownload) {
      _cancelAllTasks();
      return;
    }

    final activeTag = _currentProfileTag;

    final desired = _desiredSongs();
    final desiredIds = desired.map((s) => s.id).toSet();

    for (final id in _tasks.keys.toList()) {
      if (!desiredIds.contains(id) || _tasks[id]!.transcodeTag != activeTag) {
        _cancelTask(id);
      }
    }

    for (final id in _cached.keys.toList()) {
      if (id == _queue.current.value?.id) continue;
      if (!desiredIds.contains(id) || _cached[id] != activeTag) {
        _evictCached(id);
      }
    }

    for (final id in _partial.keys.toList()) {
      if (_tasks.containsKey(id)) continue;
      if (!desiredIds.contains(id) || _partial[id] != activeTag) {
        _discardPartial(id);
      }
    }

    for (final song in desired) {
      if (_tasks.isNotEmpty) break;
      final id = song.id;
      if (_songDownloader.isDownloaded(id)) continue;
      if (_cached[id] == activeTag) continue;
      if (_tasks.containsKey(id)) continue;
      _startTask(song, activeTag);
    }
  }

  List<Song> _desiredSongs() {
    final desired = <Song>[];
    for (final s in _prioWindow) {
      if (desired.length >= _settings.count) break;
      desired.add(s);
    }
    for (final s in _regularWindow) {
      if (desired.length >= _settings.count) break;
      desired.add(s);
    }
    return desired;
  }

  void _discardPartial(String id) {
    final tag = _partial.remove(id);
    if (tag != null) {
      _deleteFile(_partPath(id, tag));
    }
  }

  void _startTask(Song song, String transcodeTag) {
    final task = _PrefetchTask(song: song, transcodeTag: transcodeTag);
    if (_partial[song.id] == transcodeTag) {
      task.canResume = true;
    }
    _tasks[song.id] = task;
    Log.trace("prefetch enqueue ${song.id} (${song.title})");
    _runTask(task);
  }

  void _cancelTask(String id) {
    final task = _tasks.remove(id);
    if (task == null) return;
    task.canceled = true;
    task.abort?.call();
  }

  void _cancelAllTasks() {
    for (final id in _tasks.keys.toList()) {
      _cancelTask(id);
    }
  }

  Future<void> _runTask(_PrefetchTask task) async {
    final id = task.song.id;
    int attempt = 0;
    bool completed = false;
    try {
      while (!task.canceled) {
        if (!_canDownload || task.transcodeTag != _currentProfileTag) break;

        if (await _isOffline()) {
          await _waitForConnectivity(task);
          if (task.canceled) break;
          continue;
        }

        try {
          if (await _attemptDownload(task)) {
            _cached[id] = task.transcodeTag;
            completed = true;
            Log.debug("prefetch completed $id (${task.transcodeTag})");
            _songCachedController.add(task.song);
            notifyListeners();
            break;
          }
          if (task.canceled) break;
        } catch (e) {
          if (task.canceled) break;
          Log.debug("prefetch attempt failed for $id: $e");
        }

        attempt++;
        await _delay(_backoff(attempt), task);
      }
    } finally {
      _tasks.remove(id);
      if (completed) {
        _partial.remove(id);
      } else if (task.transcodeTag == _currentProfileTag &&
          task.canResume &&
          _desiredSongs().any((s) => s.id == id)) {
        // keep the partial file so a future task can resume it instead of
        // restarting from scratch (e.g. after throttling or a brief stall)
        _partial[id] = task.transcodeTag;
      } else {
        _partial.remove(id);
        await _deleteFile(_partPath(id, task.transcodeTag));
      }
      _scheduleReconcile();
    }
  }

  Future<bool> _attemptDownload(_PrefetchTask task) async {
    final id = task.song.id;
    final partFile = File(_partPath(id, task.transcodeTag));

    int received = 0;
    bool append = false;
    if (task.canResume && await partFile.exists()) {
      final existing = await partFile.length();
      if (existing > 0) {
        received = existing;
        append = true;
      }
    }
    if (!append) {
      task.received = 0;
      task.canResume = false;
      if (await partFile.exists()) {
        try {
          await partFile.delete();
        } catch (_) {}
      }
    }

    _currentDownloadSongId.add(id);
    try {
      final request = http.Request("GET", _streamUriFor(id));
      if (append && received > 0) {
        request.headers["range"] = "bytes=$received-";
      }

      final response = await _client.send(request).timeout(_connectTimeout);

      if (task.canceled) {
        response.stream.drain<void>().catchError((_) {});
        return false;
      }

      if (append && received > 0 && response.statusCode != 206) {
        append = false;
        received = 0;
        task.received = 0;
        task.canResume = false;
      }
      if (!append && response.statusCode != 200) {
        response.stream.drain<void>().catchError((_) {});
        throw _PrefetchException("unexpected status ${response.statusCode}");
      }

      int? declaredTotal;
      if (response.statusCode == 206) {
        declaredTotal = _parseContentRangeTotal(
          response.headers["content-range"],
        );
      } else if (response.contentLength != null) {
        declaredTotal = response.contentLength;
      }
      final acceptRanges =
          (response.headers["accept-ranges"]?.toLowerCase() ?? "") == "bytes";
      task.canResume = acceptRanges && declaredTotal != null;

      final sink = partFile.openWrite(
        mode: append ? FileMode.writeOnlyAppend : FileMode.writeOnly,
      );

      final completer = Completer<bool>();
      final started = DateTime.now();
      final cap = _totalTimeCap(task.song.duration);
      Timer? stall;
      StreamSubscription<List<int>>? sub;

      void finish(bool ok, [Object? err]) {
        stall?.cancel();
        final s = sub;
        sub = null;
        s?.cancel();
        if (!completer.isCompleted) {
          if (err != null) {
            completer.completeError(err);
          } else {
            completer.complete(ok);
          }
        }
      }

      void resetStall() {
        stall?.cancel();
        stall = Timer(
          _stallTimeout,
          () => finish(false, _PrefetchException("stall")),
        );
      }

      task.abort = () => finish(false);
      resetStall();
      sub = response.stream.listen(
        (chunk) {
          sink.add(chunk);
          received += chunk.length;
          task.received = received;
          resetStall();
          if (DateTime.now().difference(started) > cap) {
            finish(false, _PrefetchException("total time cap exceeded"));
          }
        },
        onError: (Object e) => finish(false, e),
        onDone: () => finish(true),
        cancelOnError: true,
      );

      bool ok;
      try {
        ok = await completer.future;
      } finally {
        task.abort = null;
        await sink.flush();
        await sink.close();
      }

      if (task.canceled || !ok) return false;

      if (declaredTotal != null && received != declaredTotal) {
        throw _PrefetchException(
          "incomplete download $received/$declaredTotal",
        );
      }

      await partFile.rename(_finalPath(id, task.transcodeTag));
      return true;
    } finally {
      _currentDownloadSongId.add(null);
    }
  }

  Uri _streamUriFor(String id) {
    final con = _auth.con;
    final query = _subsonic.generateQuery({
      "id": [id],
      if (_format != null) "format": [_format!],
      if (_maxBitRate != null) "maxBitRate": [_maxBitRate!.toString()],
    }, con.auth);
    return Uri.parse(
      '${con.baseUri}/rest/stream${Uri(queryParameters: query)}',
    );
  }

  Future<bool> _isOffline() async {
    final result = await Connectivity().checkConnectivity();
    return result.isEmpty || result.contains(ConnectivityResult.none);
  }

  Future<void> _waitForConnectivity(_PrefetchTask task) async {
    if (!await _isOffline()) return;
    Log.trace("prefetch waiting for connectivity (${task.song.id})");
    final completer = Completer<void>();
    StreamSubscription? sub;
    void done() {
      sub?.cancel();
      if (!completer.isCompleted) completer.complete();
    }

    sub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
        done();
      }
    });
    task.abort = done;
    await completer.future;
    task.abort = null;
  }

  Future<void> _delay(Duration d, _PrefetchTask task) async {
    final completer = Completer<void>();
    final timer = Timer(d, () {
      if (!completer.isCompleted) completer.complete();
    });
    task.abort = () {
      timer.cancel();
      if (!completer.isCompleted) completer.complete();
    };
    await completer.future;
    task.abort = null;
  }

  Duration _backoff(int attempt) {
    final seconds = min(60, 2 * pow(2, min(attempt, 5)).toInt());
    return Duration(seconds: seconds, milliseconds: _rand.nextInt(1000));
  }

  Duration _totalTimeCap(Duration? duration) {
    if (duration == null) return const Duration(minutes: 10);
    return duration * 4 + const Duration(seconds: 30);
  }

  int? _parseContentRangeTotal(String? header) {
    if (header == null) return null;
    final idx = header.lastIndexOf('/');
    if (idx < 0) return null;
    final total = header.substring(idx + 1).trim();
    if (total == "*") return null;
    return int.tryParse(total);
  }

  String _finalPath(String id, String tag) => path.join(_dir!, "$id-$tag");

  String _partPath(String id, String tag) => path.join(_dir!, "$id-$tag.part");

  Future<void> _deleteFile(String filePath) async {
    try {
      final f = File(filePath);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  void _evictCached(String id) {
    if (id == _queue.current.value?.id) return;
    if (_cached.remove(id) == null) return;
    _deleteCachedFiles(id);
    _songRemovedFromCacheController.add(id);
    notifyListeners();
  }

  Future<void> _deleteCachedFiles(String id) async {
    if (_dir == null) return;
    try {
      await for (final f in Directory(_dir!).list()) {
        final name = path.basename(f.path);
        if (name == id || name.startsWith("$id-")) {
          try {
            await f.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _reconcileDebounce?.cancel();
    _windowDebounce?.cancel();
    _queue.removeListener(_scheduleWindowUpdate);
    _settings.removeListener(_onSettingsChanged);
    _transcoding.removeListener(_updateTranscoding);
    _auth.removeListener(_onAuthChanged);
    _cancelAllTasks();
    _songCachedController.close();
    _songRemovedFromCacheController.close();
    _client.close();
    super.dispose();
  }
}
