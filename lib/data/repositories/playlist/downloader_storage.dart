import 'dart:convert';

import 'package:background_downloader/background_downloader.dart';
import 'package:crossonic/data/services/database/database.dart' as db;
import 'package:crossonic/utils/exceptions.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

class DownloaderStorage implements PersistentStorage {
  static Future<void> register(db.Database db) async {
    if (kIsWeb) return;
    final ready =
        await FileDownloader(persistentStorage: DownloaderStorage(db: db))
            .ready;
    if (!ready) {
      throw AppException("Failed to initialize file downloader");
    }
  }

  final db.Database _db;

  static const typePaused = "paused";
  static const typeResume = "resume";
  static const typeRecord = "record";

  DownloaderStorage({required db.Database db}) : _db = db;

  @override
  Future<void> initialize() async {
    await _purgeOldRecords();
  }

  @override
  Future<void> removePausedTask(String? taskId) async {
    return _remove(typePaused, taskId);
  }

  @override
  Future<void> removeResumeData(String? taskId) async {
    return _remove(typeResume, taskId);
  }

  @override
  Future<void> removeTaskRecord(String? taskId) async {
    return _remove(typeRecord, taskId);
  }

  @override
  Future<List<Task>> retrieveAllPausedTasks() {
    return _retrieveAll(typePaused, Task.createFromJson);
  }

  @override
  Future<List<ResumeData>> retrieveAllResumeData() {
    return _retrieveAll(typeResume, ResumeData.fromJson);
  }

  @override
  Future<List<TaskRecord>> retrieveAllTaskRecords() {
    return _retrieveAll(typeRecord, TaskRecord.fromJson);
  }

  @override
  Future<Task?> retrievePausedTask(String taskId) {
    return _retrieveSingle(typePaused, taskId, Task.createFromJson);
  }

  @override
  Future<ResumeData?> retrieveResumeData(String taskId) {
    return _retrieveSingle(typeResume, taskId, ResumeData.fromJson);
  }

  @override
  Future<TaskRecord?> retrieveTaskRecord(String taskId) {
    return _retrieveSingle(typeRecord, taskId, TaskRecord.fromJson);
  }

  @override
  Future<void> storePausedTask(Task task) async {
    await _db.managers.downloadTask.create(
      (o) => o(
        taskId: task.taskId,
        group: Value(task.group),
        type: typePaused,
        updated: DateTime.now(),
        object: jsonEncode(task),
      ),
      mode: InsertMode.replace,
    );
  }

  @override
  Future<void> storeResumeData(ResumeData resumeData) async {
    await _db.managers.downloadTask.create(
      (o) => o(
        taskId: resumeData.taskId,
        type: typeResume,
        updated: DateTime.now(),
        object: jsonEncode(resumeData),
      ),
      mode: InsertMode.replace,
    );
  }

  @override
  Future<void> storeTaskRecord(TaskRecord record) async {
    await _db.managers.downloadTask.create(
      (o) => o(
        taskId: record.taskId,
        type: typeRecord,
        updated: DateTime.now(),
        object: jsonEncode(record),
        group: Value(record.group),
        status: Value(record.status.name),
      ),
      mode: InsertMode.replace,
    );
  }

  Future<void> _purgeOldRecords(
      {Duration age = const Duration(days: 30)}) async {
    final cutOff = DateTime.now().subtract(age);
    await _db.managers.downloadTask
        .filter((f) => f.updated.isBefore(cutOff))
        .delete();
  }

  Future<void> _remove(String type, String? taskId) async {
    if (taskId != null) {
      await _db.managers.downloadTask
          .filter((f) => f.type(type) & f.taskId(taskId))
          .delete();
    } else {
      await _db.managers.downloadTask.filter((f) => f.type(type)).delete();
    }
  }

  Future<List<T>> _retrieveAll<T>(
      String type, T Function(Map<String, dynamic>) fromJson) async {
    final records =
        await _db.managers.downloadTask.filter((f) => f.type(type)).get();
    return records
        .map((r) => fromJson(jsonDecode(r.object)))
        .toList(growable: false);
  }

  Future<T?> _retrieveSingle<T>(String type, String taskId,
      T Function(Map<String, dynamic>) fromJson) async {
    final record = await _db.managers.downloadTask
        .filter((f) => f.type(type) & f.taskId(taskId))
        .getSingleOrNull();
    if (record == null) return null;
    return fromJson(jsonDecode(record.object));
  }

  @override
  Future<(String, int)> get storedDatabaseVersion async =>
      ("DownloaderStorage", 1);

  @override
  (String, int) get currentDatabaseVersion => ("DownloaderStorage", 1);
}
