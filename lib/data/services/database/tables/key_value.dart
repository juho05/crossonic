/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart';

class KeyValueTable extends Table {
  late final key = text()();
  late final value = text()();

  @override
  Set<Column<Object>> get primaryKey => {key};

  @override
  String? get tableName => "key_value";
}
