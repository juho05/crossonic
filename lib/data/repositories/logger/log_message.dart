/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:logger/logger.dart';

class LogMessage {
  // null for messages that have not been persisted yet
  final int? id;
  final DateTime sessionStartTime;
  final DateTime time;
  final Level level;
  final String tag;
  final String message;
  // null if the message was loaded without its stack trace
  final String? stackTrace;
  final String? exception;

  LogMessage({
    this.id,
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
    if (stackTrace == null) return msg;
    return "$msg\n${stackTrace!.split("\n").take(_stackTraceLines[level] ?? 50).join("\n")}";
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
