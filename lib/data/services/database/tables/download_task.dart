/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart';

class DownloadTask extends Table {
  late final taskId = text()();
  late final type = text()();
  late final object = text()();

  late final group = text().nullable()();
  late final status = text().nullable()();
  late final updated = dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {taskId, type};

  @override
  String? get tableName => "download_task";
}
