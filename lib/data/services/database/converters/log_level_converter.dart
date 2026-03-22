/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart';
import 'package:logger/logger.dart';

class LogLevelConverter extends TypeConverter<Level, String> {
  const LogLevelConverter();

  @override
  Level fromSql(String fromDb) {
    return Level.values.byName(fromDb);
  }

  @override
  String toSql(Level value) {
    return value.name;
  }
}
