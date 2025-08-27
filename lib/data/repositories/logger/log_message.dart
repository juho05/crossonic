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
      msg += ": $exception";
    }
    return "$msg\n${stackTrace.toString().split("\n").take(10)}";
  }
}
