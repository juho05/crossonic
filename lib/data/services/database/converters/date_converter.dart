/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart';

class Date implements Comparable<Date> {
  final int year;
  final int? month;
  final int? day;

  Date({required this.year, required this.month, required this.day});

  factory Date.parse(String str) {
    final parts = str.split("-");
    final year = int.parse(parts.first, radix: 10);
    final month = int.tryParse(parts.elementAtOrNull(1) ?? "", radix: 10);
    final day = int.tryParse(parts.elementAtOrNull(2) ?? "", radix: 10);
    return Date(year: year, month: month, day: day);
  }

  @override
  String toString() {
    var s = year.toString().padLeft(4, "0");
    if (month != null) {
      s += "-${month.toString().padLeft(2, "0")}";
    }
    if (day != null) {
      s += "-${day.toString().padLeft(2, "0")}";
    }
    return s;
  }

  bool operator >(Date other) {
    if (year != other.year) return year > other.year;
    if ((month ?? 1) != (other.month ?? 1)) {
      return (month ?? 1) > (other.month ?? 1);
    }
    return (day ?? 1) > (other.day ?? 1);
  }

  bool operator <(Date other) {
    if (year != other.year) return year < other.year;
    if ((month ?? 1) != (other.month ?? 1)) {
      return (month ?? 1) < (other.month ?? 1);
    }
    return (day ?? 1) < (other.day ?? 1);
  }

  @override
  bool operator ==(Object other) {
    if (other is! Date) return false;
    return year == other.year &&
        (month ?? 1) == (other.month ?? 1) &&
        (day ?? 1) == (other.day ?? 1);
  }

  @override
  int get hashCode => Object.hash(year, month, day);

  bool operator >=(Date other) {
    return this > other || this == other;
  }

  bool operator <=(Date other) {
    return this < other || this == other;
  }

  @override
  int compareTo(Date other) {
    if (this == other) return 0;
    return this < other ? -1 : 1;
  }
}

class DateConverter extends TypeConverter<Date, String> {
  const DateConverter();

  @override
  Date fromSql(String fromDb) {
    return Date.parse(fromDb);
  }

  @override
  String toSql(Date value) {
    return value.toString();
  }
}
