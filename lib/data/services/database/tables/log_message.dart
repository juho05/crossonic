import 'package:crossonic/data/services/database/converters/log_level_converter.dart';
import 'package:drift/drift.dart';

class LogMessageTable extends Table {
  late final id = integer().autoIncrement()();
  late final sessionStartTime = dateTime()();
  late final time = dateTime()();
  late final level = text().map(const LogLevelConverter())();
  late final tag = text()();
  late final message = text()();
  late final stackTrace = text()();
  late final exception = text().nullable()();

  @override
  String? get tableName => "log_message";
}
