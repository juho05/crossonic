import 'package:drift/drift.dart';

class CoverCacheTable extends Table {
  late final coverId = text()();
  late final size = integer()();
  late final fileFullyWritten = boolean()();
  late final downloadTime = dateTime()();
  late final validTill = dateTime()();
  late final fileSizeKB = integer()();

  @override
  Set<Column<Object>> get primaryKey => {coverId, size};

  @override
  String? get tableName => "cover_cache";
}
