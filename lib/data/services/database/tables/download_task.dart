import 'package:drift/drift.dart';

class DownloadTask extends Table {
  late final taskId = text()();
  late final type = text()();
  late final object = text()();

  late final group = text().nullable()();
  late final status = text().nullable()();
  late final updated = dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {taskId, type};

  @override
  String? get tableName => "download_task";
}
