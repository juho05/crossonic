import 'package:drift/drift.dart';

class KeyValueTable extends Table {
  late final key = text()();
  late final value = text()();

  @override
  Set<Column<Object>> get primaryKey => {key};

  @override
  String? get tableName => "key_value";
}
