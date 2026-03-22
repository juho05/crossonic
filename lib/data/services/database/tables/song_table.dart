/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/services/database/converters/artist_ref_list_converter.dart';
import 'package:crossonic/data/services/database/converters/date_converter.dart';
import 'package:crossonic/data/services/database/converters/string_list_converter.dart';
import 'package:drift/drift.dart';

class SongTable extends Table {
  late final id = text()();
  late final coverId = text()();
  late final title = text()();
  late final displayArtist = text()();
  late final artists = text()
      .map(const ArtistRefListConverter())
      .clientDefault(() => "[]")();
  late final albumId = text().nullable()();
  late final albumName = text().nullable()();
  late final genres = text()
      .map(const StringListConverter())
      .clientDefault(() => "[]")();
  late final durationMs = integer().nullable()();
  late final bpm = integer().nullable()();
  late final trackNr = integer().nullable()();
  late final discNr = integer().nullable()();
  late final trackGain = real().nullable()();
  late final albumGain = real().nullable()();
  late final fallbackGain = real().nullable()();
  late final originalDate = text().map(const DateConverter()).nullable()();
  late final releaseDate = text().map(const DateConverter()).nullable()();

  late final updated = dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  String? get tableName => "song";
}
