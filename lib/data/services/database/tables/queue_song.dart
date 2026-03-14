import 'package:crossonic/data/services/database/tables/queue.dart';
import 'package:crossonic/data/services/database/tables/song_table.dart';
import 'package:drift/drift.dart';

@TableIndex(
  name: 'queue_song_index',
  columns: {IndexedColumn(#index, orderBy: OrderingMode.asc)},
)
class QueueSongTable extends Table {
  late final id = integer().autoIncrement()();
  late final queueId = text().references(
    QueueTable,
    #id,
    onDelete: KeyAction.cascade,
    onUpdate: KeyAction.cascade,
  )();
  late final index = integer()();
  late final songId = text().references(SongTable, #id)();

  @override
  String? get tableName => "queue_song";
}
