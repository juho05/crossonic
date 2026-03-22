/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart';

class ScrobbleTable extends Table {
  late final songId = text()();
  late final startTime = dateTime()();
  late final listenDurationMs = integer()();
  late final songDurationMs = integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {songId, startTime};

  @override
  String? get tableName => "scrobble";
}
