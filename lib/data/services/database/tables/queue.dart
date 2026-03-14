import 'package:drift/drift.dart';

class QueueTable extends Table {
  late final id = text()();
  late final name = text()();
  late final currentIndex = integer().clientDefault(() => -1)();
  late final loop = boolean().clientDefault(() => false)();

  @override
  Set<Column<Object>>? get primaryKey => {id};

  @override
  String? get tableName => "queue";
}
