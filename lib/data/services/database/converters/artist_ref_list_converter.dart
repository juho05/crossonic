/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:convert';

import 'package:drift/drift.dart';

class ArtistRef {
  final String id;
  final String name;

  ArtistRef({required this.id, required this.name});

  @override
  bool operator ==(Object other) {
    if (other is! ArtistRef) return false;
    return id == other.id && name == other.name;
  }

  @override
  int get hashCode => Object.hash(id, name);
}

class ArtistRefListConverter extends TypeConverter<List<ArtistRef>, String> {
  const ArtistRefListConverter();

  @override
  List<ArtistRef> fromSql(String fromDb) {
    return (jsonDecode(fromDb) as List<dynamic>)
        .map((ref) => ArtistRef(id: ref['id'], name: ref['name']))
        .toList();
  }

  @override
  String toSql(List<ArtistRef> value) {
    return jsonEncode(
      value.map((ref) => {"id": ref.id, "name": ref.name}).toList(),
    );
  }
}
