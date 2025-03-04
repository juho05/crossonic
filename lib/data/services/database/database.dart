import 'package:crossonic/data/services/database/database.steps.dart';
import 'package:crossonic/data/services/database/log_interceptor.dart';
import 'package:crossonic/data/services/database/tables/key_value.dart';
import 'package:crossonic/data/services/database/tables/scrobble.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

@DriftDatabase(tables: [KeyValue, Scrobble])
class Database extends _$Database {
  Database([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 2;

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
        onUpgrade: (m, from, to) async {
          await customStatement("PRAGMA foreign_keys = OFF");

          await transaction(
            () async => m.runMigrationSteps(
              from: from,
              to: to,
              steps: migrationSteps(
                from1To2: (m, schema) async {
                  await m.createTable(schema.scrobble);
                },
              ),
            ),
          );

          if (kDebugMode) {
            // Fail if the migration broke foreign keys
            final wrongForeignKeys =
                await customSelect('PRAGMA foreign_key_check').get();
            assert(wrongForeignKeys.isEmpty,
                '${wrongForeignKeys.map((e) => e.data)}');
          }

          await customStatement("PRAGMA foreign_keys = ON");
        },
        beforeOpen: (details) async {
          await customStatement("PRAGMA foreign_keys = ON");
        },
      );

  static QueryExecutor _openConnection() {
    final db = driftDatabase(
      name: "crossonic_database",
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
    if (kDebugMode) {
      return db.interceptWith(LogInterceptor());
    }
    return db;
  }
}
