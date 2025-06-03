import 'package:drift/drift.dart';

class PlaylistTable extends Table {
  late final id = text()();
  late final name = text()();
  late final comment = text().nullable()();
  late final songCount = integer()();
  late final durationMs = integer()();
  late final created = dateTime()();
  late final changed = dateTime()();
  late final coverArt = text().nullable()();
  late final download = boolean().withDefault(const Variable(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  String? get tableName => "playlist";
}
