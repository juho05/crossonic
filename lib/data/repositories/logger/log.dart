import 'package:crossonic/data/repositories/logger/log_message.dart';
import 'package:crossonic/data/repositories/logger/log_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class Log {
  static late final Logger _logger;
  static late final LogRepository _repo;
  static late final DateTime sessionStartTime;

  static const String _excludePath =
      "package:crossonic/data/repositories/logger/log.dart";

  static void init(LogRepository repository) {
    sessionStartTime = DateTime.now();
    _repo = repository;
    Logger.level = level;
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 5,
        errorMethodCount: 10,
        excludePaths: [
          _excludePath,
        ],
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
      error("uncaught exception: ${details.exception.toString()}",
          e: details.exception, st: details.stack, tag: "FlutterError.onError");
    };

    PlatformDispatcher.instance.onError = (err, stack) {
      error("uncaught exception",
          e: err, st: stack, tag: "PlatformDispatcher.onError");
      return true;
    };
  }

  static Level _level = kDebugMode ? Level.debug : Level.info;

  static set level(Level level) {
    _level = level;
    Logger.level = _level;
  }

  static Level get level => _level;

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

  static void _log(Level level, String msg,
      {Object? e, StackTrace? st, String? tag}) {
    if (Log.level > level || level >= Level.off) return;
    tag ??= _getCallerTag(3);
    st ??= StackTrace.current;
    _logger.log(level, "[$tag] $msg", error: e, stackTrace: st);
    _repo.store(LogMessage(
      sessionStartTime: sessionStartTime,
      time: DateTime.now(),
      tag: tag,
      stackTrace: _formatFullStackTrace(st),
      exception: e?.toString(),
      level: level,
      message: msg,
    ));
  }

  static void logWithoutPersistence(Level level, String msg,
      {Object? e, StackTrace? st, String? tag}) {
    if (Log.level > level || level >= Level.off) return;
    tag ??= _getCallerTag(2);
    st ??= StackTrace.current;
    _logger.log(level, "[$tag] $msg", error: e, stackTrace: st);
  }

  static String _getCallerTag(int traceLineIndex) {
    try {
      final traceString =
          StackTrace.current.toString().split('\n')[traceLineIndex];
      final match = RegExp(r'#' + traceLineIndex.toString() + r'\s+(\S+)')
          .firstMatch(traceString);
      if (match != null && match.groupCount >= 1) {
        return match.group(1) ?? 'Unknown';
      }
    } catch (_) {}
    return 'Unknown';
  }

  static String _formatFullStackTrace(StackTrace st) {
    return PrettyPrinter(
          excludePaths: [_excludePath],
        ).formatStackTrace(st, null) ??
        st.toString();
  }
}
