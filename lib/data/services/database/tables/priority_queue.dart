/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/services/database/tables/song_table.dart';
import 'package:drift/drift.dart';

@TableIndex(
  name: 'prio_queue_song_index',
  columns: {IndexedColumn(#index, orderBy: OrderingMode.asc)},
)
class PriorityQueueSongTable extends Table {
  late final id = integer().autoIncrement()();
  late final index = integer()();
  late final songId = text().references(SongTable, #id)();

  @override
  String? get tableName => "priority_queue";
}
