import 'package:crossonic/data/services/database/tables/key_value.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

@DriftDatabase(tables: [KeyValue])
class Database extends _$Database {
  Database() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<void> clearAll() async {
    customStatement("PRAGMA foreign_keys = OFF");
    try {
      await transaction(() async {
        for (var table in allTables) {
          await delete(table).go();
        }
      });
    } finally {
      customStatement("PRAGMA foreign_keys = ON");
    }
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement("PRAGMA foreign_keys = ON");
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: "crossonic_database",
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
