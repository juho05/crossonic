import 'package:drift/drift.dart';
import 'package:logger/logger.dart';

class LogLevelConverter extends TypeConverter<Level, String> {
  const LogLevelConverter();

  @override
  Level fromSql(String fromDb) {
    return Level.values.byName(fromDb);
  }

  @override
  String toSql(Level value) {
    return value.name;
  }
}
