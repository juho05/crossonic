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
