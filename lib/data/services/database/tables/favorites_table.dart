/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart';

class FavoritesTable extends Table {
  late final id = text()();
  late final starred = dateTime()();
  // song,album,artist
  late final type = text()();

  @override
  Set<Column<Object>>? get primaryKey => {id, type};

  @override
  String? get tableName => "favorites";
}
