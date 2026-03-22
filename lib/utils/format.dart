/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math';

import 'package:intl/intl.dart';

String formatDuration(Duration d, {bool long = false}) {
  if (long) {
    return '${d.inHours > 0 ? '${d.inHours}h ' : ''}${d.inMinutes.remainder(60).toString().padLeft(2, '0')}min ${d.inSeconds.remainder(60).toString().padLeft(2, '0')}s';
  }
  return '${d.inHours > 0 ? '${d.inHours}:' : ''}${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
}

String formatDateValues(int year, [int? month, int? day]) {
  String result = year.toString().padLeft(4, "0");
  if (month != null) {
    result += "-${month.toString().padLeft(2, "0")}";
  }
  if (day != null) {
    result += "-${day.toString().padLeft(2, "0")}";
  }
  return result;
}

String formatDate(DateTime d) {
  d = d.toLocal();
  DateFormat format = DateFormat("yyyy-MM-dd");
  return format.format(d);
}

String formatDateTime(DateTime d) {
  d = d.toLocal();
  DateFormat format = DateFormat("yyyy-MM-dd HH:mm:ss");
  return format.format(d);
}

String formatBoolToYesNo(bool b) {
  return b ? "yes" : "no";
}

String formatDouble(double d, {int precision = 2}) {
  return ((d * pow(10, precision)).roundToDouble() / pow(10, precision))
      .toString();
}
