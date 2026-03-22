/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart';

class CoverCacheTable extends Table {
  late final coverId = text()();
  late final size = integer()();
  late final fileFullyWritten = boolean()();
  late final downloadTime = dateTime()();
  late final validTill = dateTime()();
  late final fileSizeKB = integer()();

  @override
  Set<Column<Object>> get primaryKey => {coverId, size};

  @override
  String? get tableName => "cover_cache";
}
