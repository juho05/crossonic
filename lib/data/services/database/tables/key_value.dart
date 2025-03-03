import 'package:drift/drift.dart';

class KeyValue extends Table {
  late final key = text()();
  late final value = text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
