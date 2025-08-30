import 'package:logger/logger.dart';

class LogMessage {
  final DateTime sessionStartTime;
  final DateTime time;
  final Level level;
  final String tag;
  final String message;
  final String stackTrace;
  final String? exception;

  LogMessage({
    required this.sessionStartTime,
    required this.time,
    required this.level,
    required this.tag,
    required this.message,
    required this.exception,
    required this.stackTrace,
  });

  @override
  String toString() {
    String msg = "[${level.name.toUpperCase()}] $time: $tag: $message";
    if (exception != null) {
      msg += "\nException: $exception";
    }
    return "$msg\n${stackTrace.split("\n").take(_stackTraceLines[level] ?? 50).join("\n")}";
  }

  static const Map<Level, int> _stackTraceLines = {
    Level.trace: 3,
    Level.debug: 5,
    Level.info: 10,
    Level.warning: 20,
    Level.error: 50,
    Level.fatal: 50,
  };
}
