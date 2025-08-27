import 'dart:async';
import 'dart:collection';

import 'package:crossonic/data/repositories/logger/log_message.dart';
import 'package:crossonic/data/services/database/database.dart';
import 'package:drift/drift.dart';
import 'package:logger/logger.dart';

import 'log.dart';

class LogRepository {
  static final int _maxBufferSize = 50;
  static final Duration _bufferDebounceDuration = const Duration(seconds: 3);

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
  }

  Future<void> store(LogMessage msg) async {
    if (_db == null) {
      _buffer.add(msg);
      return;
    }

    if (msg.level >= Level.error) {
      await _flushMessage(msg);
      return;
    }

    _buffer.add(msg);

    if (!_flushing && _buffer.length >= _maxBufferSize) {
      await _flushBuffer();
      return;
    }

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
}
