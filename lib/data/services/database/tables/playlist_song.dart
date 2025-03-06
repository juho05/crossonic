import 'package:crossonic/data/services/database/tables/playlist.dart';
import 'package:drift/drift.dart';

class PlaylistSongTable extends Table {
  late final playlistId =
      text().references(PlaylistTable, #id, onDelete: KeyAction.cascade)();
  late final index = integer()();
  late final songId = text()();
  late final childModelJson = text()();

  @override
  Set<Column<Object>> get primaryKey => {playlistId, index};

  @override
  String? get tableName => "playlist_song";
}
