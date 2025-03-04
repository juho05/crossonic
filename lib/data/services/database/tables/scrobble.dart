import 'package:drift/drift.dart';

class Scrobble extends Table {
  late final songId = text()();
  late final startTime = dateTime()();
  late final listenDurationMs = integer()();
  late final songDurationMs = integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {songId, startTime};
}
