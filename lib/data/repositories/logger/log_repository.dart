import 'dart:async';
import 'dart:collection';

import 'package:crossonic/data/repositories/logger/log_message.dart';
import 'package:crossonic/data/services/database/database.dart';
import 'package:drift/drift.dart';
import 'package:logger/logger.dart';

import 'log.dart';

class LogRepository {
  static final Duration _bufferDebounceDuration = const Duration(seconds: 2);

  final StreamController<LogMessage> _newMessageStream =
      StreamController.broadcast();
  Stream<LogMessage> get newMessageStream => _newMessageStream.stream;

  Database? _db;
  Queue<LogMessage> _buffer;

  bool _flushing = false;
  Timer? _debounceTimer;

  LogRepository({
    Database? db,
  })  : _db = db,
        _buffer = DoubleLinkedQueue();

  Future<void> enablePersistence(Database db) async {
    assert(_db == null);
    _db = db;
    await _flushBuffer();
    await _deleteOldLogs();
  }

  Future<void> store(LogMessage msg) async {
    _newMessageStream.add(msg);

    if (_db == null) {
      _buffer.add(msg);
      return;
    }

    if (msg.level >= Level.error) {
      await _flushMessage(msg);
      return;
    }

    _buffer.add(msg);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_bufferDebounceDuration, () async {
      await _flushBuffer();
    });
  }

  Future<void> _flushMessage(LogMessage msg) async {
    try {
      await _db!.managers.logMessageTable.create(
        (o) => o(
          time: msg.time,
          sessionStartTime: msg.sessionStartTime,
          message: msg.message,
          level: msg.level,
          tag: msg.tag,
          exception: Value(msg.exception),
          stackTrace: msg.stackTrace,
        ),
      );
    } catch (e, st) {
      _buffer.add(msg);
      Log.logWithoutPersistence(Level.error, "failed to flush log message",
          e: e, st: st);
      _buffer.add(LogMessage(
        sessionStartTime: msg.sessionStartTime,
        message: "failed to flush log message",
        level: Level.error,
        exception: e.toString(),
        stackTrace: st.toString(),
        tag: "LogRepository._flushMessage",
        time: DateTime.now(),
      ));
    }
  }

  Future<void> _flushBuffer() async {
    if (_flushing) return;
    _flushing = true;

    _debounceTimer?.cancel();
    _debounceTimer = null;

    if (_buffer.isEmpty) return;

    final buffer = _buffer;
    _buffer = DoubleLinkedQueue();
    try {
      await _db!.managers.logMessageTable.bulkCreate(
        (o) => buffer.map(
          (e) => o(
              tag: e.tag,
              level: e.level,
              message: e.message,
              sessionStartTime: e.sessionStartTime,
              time: e.time,
              stackTrace: e.stackTrace,
              exception: Value(e.exception)),
        ),
      );
    } catch (e, st) {
      _buffer = buffer;
      Log.logWithoutPersistence(Level.error, "failed to flush log messages",
          e: e, st: st);
      _buffer.add(LogMessage(
        sessionStartTime: _buffer.last.sessionStartTime,
        message: "failed to flush log messages",
        level: Level.error,
        exception: e.toString(),
        stackTrace: st.toString(),
        tag: "LogRepository._flushBuffer",
        time: DateTime.now(),
      ));
    } finally {
      _flushing = false;
    }
  }

  Future<List<LogMessage>> getMessages(DateTime sessionTime) async {
    final result = await _db?.managers.logMessageTable
        .filter((f) => f.sessionStartTime(sessionTime))
        .orderBy((o) => o.time.asc())
        .get();
    final dbMessages = result?.map((e) => LogMessage(
              sessionStartTime: e.sessionStartTime,
              tag: e.tag,
              message: e.message,
              level: e.level,
              exception: e.exception,
              stackTrace: e.stackTrace,
              time: e.time,
            )) ??
        [];

    if (_buffer.isEmpty || sessionTime != Log.sessionStartTime) {
      return dbMessages.toList();
    }

    if (_buffer.first.time.isAfter(dbMessages.last.time)) {
      return dbMessages.followedBy(_buffer).toList();
    }

    final dbBeforeFirstBuffer =
        dbMessages.takeWhile((msg) => msg.time.isBefore(_buffer.first.time));
    final remaining = dbMessages
        .skip(dbBeforeFirstBuffer.length)
        .followedBy(_buffer)
        .toList();
    remaining.sort((a, b) => a.time.compareTo(b.time));
    return dbBeforeFirstBuffer.followedBy(remaining).toList();
  }

  Future<List<DateTime>> getSessions() async {
    final query = _db?.selectOnly(_db!.logMessageTable, distinct: true)
      ?..addColumns([_db!.logMessageTable.sessionStartTime])
      ..orderBy([OrderingTerm.asc(_db!.logMessageTable.sessionStartTime)]);
    final result = (await query
            ?.map((row) => row.read(_db!.logMessageTable.sessionStartTime)!)
            .get()) ??
        [];
    if (!result.contains(Log.sessionStartTime)) {
      return result.followedBy([Log.sessionStartTime]).toList();
    }
    return result;
  }

  Future<void> _deleteOldLogs() async {
    await _db?.managers.logMessageTable
        .filter((f) => f.sessionStartTime
            .isBefore(Log.sessionStartTime.subtract(const Duration(days: 7))))
        .delete();
  }
}
