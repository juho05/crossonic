/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:crossonic/data/repositories/logger/log_message.dart';
import 'package:crossonic/data/repositories/logger/log_repository.dart';
import 'package:crossonic/data/services/methodchannel/method_channel_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_system_integration/flutter_system_integration.dart'
    show systemIntegrationLoggerName;
import 'package:logger/logger.dart';
import 'package:logging/logging.dart' as logging;

class Log {
  static Logger _logger = Logger(level: Level.off);
  static late final LogRepository _repo;
  static late final DateTime sessionStartTime;
  static late final MethodChannelService _methodChannel;

  static bool _initialized = false;

  static const String _excludePath =
      "package:crossonic/data/repositories/logger/log.dart";

  static void init(
    LogRepository repository,
    MethodChannelService methodChannel,
  ) {
    sessionStartTime = DateTime.now();
    _repo = repository;
    _methodChannel = methodChannel;
    _initialized = true;
    Logger.level = level;
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 5,
        errorMethodCount: 10,
        excludePaths: [_excludePath],
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.dateAndTime,
      ),
    );

    debugPrint = (String? message, {int? wrapWidth}) {
      if (message == null) return;
      debug(message, tag: "debugPrint");
    };

    FlutterError.onError = (details) {
      error(
        "uncaught exception: ${details.exception.toString()}",
        e: details.exception,
        st: details.stack,
        tag: "FlutterError.onError",
      );
    };

    PlatformDispatcher.instance.onError = (err, stack) {
      error(
        "uncaught exception",
        e: err,
        st: stack,
        tag: "PlatformDispatcher.onError",
      );
      return true;
    };

    logging.Logger.root.level = logging.Level.ALL;
    logging.Logger.root.onRecord.listen(_onLoggingRecord);

    if (!kIsWeb && Platform.isAndroid) {
      _methodChannel.addEventListener((event, data) {
        if (event != "log") return;
        final level = Level.values.byName(data!["level"]);
        Object? exception;
        if (data.containsKey("exception")) {
          exception = data["exception"] as String;
        }
        StackTrace? stackTrace;
        if (data.containsKey("stackTrace")) {
          stackTrace = StackTrace.fromString(data["stackTrace"] as String);
        }
        String tag = "ANDROID";
        if (data.containsKey("tag")) {
          tag += ":${data["tag"]}";
        }
        _log(
          level,
          data["message"],
          e: exception,
          st: stackTrace,
          tag: tag,
          time: DateTime.fromMillisecondsSinceEpoch(data["time"]),
        );
      });
      _methodChannel.invokeMethod("setLogLevel", level.name);
    }
  }

  static Level _level = kDebugMode ? Level.debug : Level.info;

  static set level(Level level) {
    _level = level;
    Logger.level = _level;
    if (!kIsWeb && Platform.isAndroid) {
      _methodChannel.invokeMethod("setLogLevel", level.name);
    }
  }

  static Level get level => _level;

  static void _onLoggingRecord(logging.LogRecord record) {
    if (!record.loggerName.startsWith(systemIntegrationLoggerName)) {
      return;
    }
    final level = switch (record.level.value) {
      < 500 => Level.trace,
      < 800 => Level.debug,
      < 900 => Level.info,
      < 1000 => Level.warning,
      < 1200 => Level.error,
      _ => Level.fatal,
    };
    _log(
      level,
      record.message,
      e: record.error,
      st: record.stackTrace,
      tag: record.loggerName,
      time: record.time,
    );
  }

  static void trace(String msg, {Object? e, StackTrace? st, String? tag}) {
    _log(Level.trace, msg, e: e, st: st, tag: tag);
  }

  static void debug(String msg, {Object? e, StackTrace? st, String? tag}) {
    _log(Level.debug, msg, e: e, st: st, tag: tag);
  }

  static void info(String msg, {Object? e, StackTrace? st, String? tag}) {
    _log(Level.info, msg, e: e, st: st, tag: tag);
  }

  static void warn(String msg, {Object? e, StackTrace? st, String? tag}) {
    _log(Level.warning, msg, e: e, st: st, tag: tag);
  }

  static void error(String msg, {Object? e, StackTrace? st, String? tag}) {
    _log(Level.error, msg, e: e, st: st, tag: tag);
  }

  static void fatal(String msg, {Object? e, StackTrace? st, String? tag}) {
    _log(Level.fatal, msg, e: e, st: st, tag: tag);
  }

  static void _log(
    Level level,
    String msg, {
    Object? e,
    StackTrace? st,
    String? tag,
    DateTime? time,
  }) {
    if (Log.level > level || level >= Level.off) return;
    tag ??= _getCallerTag(3);
    st ??= StackTrace.current;
    _logger.log(level, "[$tag] $msg", error: e, stackTrace: st);
    if (!_initialized) return;
    _repo.store(
      LogMessage(
        sessionStartTime: sessionStartTime,
        time: time ?? DateTime.now(),
        tag: tag,
        stackTrace: _formatFullStackTrace(st),
        exception: e?.toString(),
        level: level,
        message: msg,
      ),
    );
  }

  static void logWithoutPersistence(
    Level level,
    String msg, {
    Object? e,
    StackTrace? st,
    String? tag,
  }) {
    if (Log.level > level || level >= Level.off) return;
    tag ??= _getCallerTag(2);
    st ??= StackTrace.current;
    _logger.log(level, "[$tag] $msg", error: e, stackTrace: st);
  }

  static String _getCallerTag(int traceLineIndex) {
    try {
      final traceString = StackTrace.current.toString().split(
        '\n',
      )[traceLineIndex];
      final match = RegExp(r'#' + traceLineIndex.toString() + r'\s+(\S+)')
          .firstMatch(traceString);
      if (match != null && match.groupCount >= 1) {
        return match.group(1) ?? 'Unknown';
      }
    } catch (_) {}
    return 'Unknown';
  }

  static String _formatFullStackTrace(StackTrace st) {
    return PrettyPrinter(excludePaths: [_excludePath])
            .formatStackTrace(st, null) ??
        st.toString();
  }
}
