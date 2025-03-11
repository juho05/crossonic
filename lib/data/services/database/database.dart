import 'package:crossonic/data/services/database/database.steps.dart';
import 'package:crossonic/data/services/database/log_interceptor.dart';
import 'package:crossonic/data/services/database/tables/download_task.dart';
import 'package:crossonic/data/services/database/tables/favorites_table.dart';
import 'package:crossonic/data/services/database/tables/key_value.dart';
import 'package:crossonic/data/services/database/tables/playlist.dart';
import 'package:crossonic/data/services/database/tables/playlist_song.dart';
import 'package:crossonic/data/services/database/tables/scrobble.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  KeyValueTable,
  ScrobbleTable,
  PlaylistTable,
  PlaylistSongTable,
  DownloadTask,
  FavoritesTable,
])
class Database extends _$Database {
  Database([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 5;

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
                from2To3: (m, schema) async {
                  await m.createTable(schema.playlist);
                  await m.createTable(schema.playlistSong);
                },
                from3To4: (m, schema) async {
                  await m.createTable(schema.downloadTask);
                },
                from4To5: (m, schema) async {
                  await m.createTable(schema.favorites);
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
          await customStatement("PRAGMA journal_mode = WAL");
        },
      );

  static QueryExecutor _openConnection() {
    final db = driftDatabase(
        name: "crossonic_database",
        native: const DriftNativeOptions(
          databaseDirectory: getApplicationSupportDirectory,
        ),
        web: DriftWebOptions(
            sqlite3Wasm: Uri.parse("sqlite3.wasm"),
            driftWorker: Uri.parse("drift_worker.dart.js")));
    if (kDebugMode) {
      return db.interceptWith(LogInterceptor());
    }
    return db;
  }
}
