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
