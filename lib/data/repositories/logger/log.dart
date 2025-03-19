import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';

class Log {
  static final talker = TalkerFlutter.init(
    logger: TalkerLogger(
      settings: TalkerLoggerSettings(
        level: _level,
      ),
    ),
  );

  static void init() {
    talker.configure(
      settings: TalkerSettings(
        useHistory: true,
        maxHistoryItems: 1000,
        useConsoleLogs: true,
      ),
      logger: TalkerLogger(
        settings: TalkerLoggerSettings(
          level: _level,
        ),
      ),
    );

    debugPrint = (String? message, {int? wrapWidth}) {
      if (message == null) return;
      debug(message);
    };

    FlutterError.onError = (details) {
      critical("FlutterError - Catch all", details.exception, details.stack);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      critical("PlatformDispatcher - Catch all", error, stack);
      return true;
    };
  }

  static LogLevel _level = kDebugMode ? LogLevel.debug : LogLevel.info;

  static set level(LogLevel level) {
    _level = level;
    talker.configure(
      logger: TalkerLogger(
        settings: TalkerLoggerSettings(
          level: _level,
        ),
      ),
    );
  }

  static LogLevel get level => _level;

  static void trace(String msg, [Object? exception, StackTrace? stackTrace]) {
    talker.verbose(msg, exception, stackTrace);
  }

  static void debug(String msg, [Object? exception, StackTrace? stackTrace]) {
    talker.debug(msg, exception, stackTrace);
  }

  static void info(String msg, [Object? exception, StackTrace? stackTrace]) {
    talker.info(msg, exception, stackTrace);
  }

  static void warn(String msg, [Object? exception, StackTrace? stackTrace]) {
    talker.warning(msg, exception, stackTrace);
  }

  static void error(String msg, [Object? exception, StackTrace? stackTrace]) {
    talker.error(msg, exception, stackTrace);
  }

  static void critical(String msg,
      [Object? exception, StackTrace? stackTrace]) {
    talker.critical(msg, exception, stackTrace);
  }

  static void clear() {
    talker.cleanHistory();
  }
}
