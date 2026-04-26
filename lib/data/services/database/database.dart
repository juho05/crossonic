/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/appimage/appimage_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/services/database/converters/artist_ref_list_converter.dart';
import 'package:crossonic/data/services/database/converters/date_converter.dart';
import 'package:crossonic/data/services/database/converters/log_level_converter.dart';
import 'package:crossonic/data/services/database/converters/string_list_converter.dart';
import 'package:crossonic/data/services/database/database.steps.dart';
import 'package:crossonic/data/services/database/log_interceptor.dart';
import 'package:crossonic/data/services/database/tables/cover_cache.dart';
import 'package:crossonic/data/services/database/tables/download_task.dart';
import 'package:crossonic/data/services/database/tables/favorites_table.dart';
import 'package:crossonic/data/services/database/tables/key_value.dart';
import 'package:crossonic/data/services/database/tables/log_message.dart';
import 'package:crossonic/data/services/database/tables/playlist.dart';
import 'package:crossonic/data/services/database/tables/playlist_song.dart';
import 'package:crossonic/data/services/database/tables/priority_queue.dart';
import 'package:crossonic/data/services/database/tables/queue.dart';
import 'package:crossonic/data/services/database/tables/queue_song.dart';
import 'package:crossonic/data/services/database/tables/scrobble.dart';
import 'package:crossonic/data/services/database/tables/song_table.dart';
import 'package:drift/drift.dart';
import 'package:drift/extensions/json1.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    KeyValueTable,
    ScrobbleTable,
    PlaylistTable,
    PlaylistSongTable,
    DownloadTask,
    FavoritesTable,
    LogMessageTable,
    CoverCacheTable,
    SongTable,
    QueueTable,
    QueueSongTable,
    PriorityQueueSongTable,
  ],
)
class Database extends _$Database {
  Database([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 10;

  Future<void> clearAll() async {
    await customStatement("PRAGMA foreign_keys = OFF");
    try {
      await transaction(() async {
        for (var table in allTables) {
          if (table == keyValueTable) {
            await managers.keyValueTable
                .filter(
                  (f) => f.key(AppImageRepository.integrationDisabledKey).not(),
                )
                .delete();
            continue;
          }
          await delete(table).go();
        }
      });
    } finally {
      await customStatement("PRAGMA foreign_keys = ON");
    }
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      await customStatement("PRAGMA foreign_keys = OFF");
      Log.info("Migrating database from schema version $from to $to");
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
            from5To6: (m, schema) async {
              await m.createTable(schema.logMessage);
            },
            from6To7: (m, schema) async {
              await m.createTable(schema.coverCache);
              await m.alterTable(
                TableMigration(
                  schema.playlistSong,
                  columnTransformer: {
                    schema.playlistSong.coverId: schema
                        .playlistSong
                        .childModelJson
                        .jsonExtract("\$.coverArt"),
                  },
                ),
              );
            },
            from7To8: (m, schema) async {
              await m.createTable(schema.song);
              await m.deleteTable(schema.playlistSong.actualTableName);
              await m.createTable(schema.playlistSong);
            },
            from8To9: (m, schema) async {
              await m.createTable(schema.queue);
              await m.createTable(schema.queueSong);
              await m.createTable(schema.priorityQueue);
              await m.createIndex(playlistSongIndex);
            },
            from9To10: (m, schema) async {
              await m.addColumn(schema.song, schema.song.contentType);
              await m.addColumn(schema.song, schema.song.sampleRate);
              await m.addColumn(schema.song, schema.song.bitDepth);
              await m.addColumn(schema.song, schema.song.bitRate);
            },
          ),
        ),
      );

      if (kDebugMode) {
        // Fail if the migration broke foreign keys
        final wrongForeignKeys = await customSelect(
          'PRAGMA foreign_key_check',
        ).get();
        assert(
          wrongForeignKeys.isEmpty,
          '${wrongForeignKeys.map((e) => e.data)}',
        );
      }

      await customStatement("PRAGMA foreign_keys = ON");
    },
    beforeOpen: (details) async {
      await customStatement("PRAGMA foreign_keys = ON");
      await customStatement("PRAGMA journal_mode = WAL");
      await customStatement("PRAGMA busy_timeout = 5000");
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
        driftWorker: Uri.parse("drift_worker.js"),
      ),
    ).interceptWith(LogInterceptor());
    return db;
  }
}
