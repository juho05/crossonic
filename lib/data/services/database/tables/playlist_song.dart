import 'package:crossonic/data/services/database/tables/playlist.dart';
import 'package:crossonic/data/services/database/tables/song_table.dart';
import 'package:drift/drift.dart';

@TableIndex(
  name: 'playlist_song_index',
  columns: {IndexedColumn(#index, orderBy: OrderingMode.asc)},
)
class PlaylistSongTable extends Table {
  late final id = integer().autoIncrement()();
  late final playlistId = text().references(
    PlaylistTable,
    #id,
    onDelete: KeyAction.cascade,
  )();
  late final index = integer()();
  late final songId = text().references(SongTable, #id)();

  @override
  String? get tableName => "playlist_song";
}
