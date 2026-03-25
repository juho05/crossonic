/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:convert';

import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/services/database/database.dart';
import 'package:drift/drift.dart';

class KeyValueRepository {
  final Database _db;

  KeyValueRepository({required Database database}) : _db = database;

  Future<void> store<T>(String key, T value) async {
    Object? object = value;
    if (object is DateTime) {
      object = object.millisecondsSinceEpoch;
    }
    Log.trace("storing new value for $key");
    await _db.managers.keyValueTable.create(
      (o) => o(key: key, value: jsonEncode(object)),
      mode: InsertMode.replace,
    );
  }

  Future<void> remove(String key) async {
    Log.trace("removing $key");
    await _db.managers.keyValueTable.filter((kv) => kv.key(key)).delete();
  }

  Future<String?> loadString(String key) async {
    final json = await _loadValue(key);
    if (json == null) return null;
    return jsonDecode(json) as String;
  }

  Future<List<String>?> loadStringList(String key) async {
    final json = await _loadValue(key);
    if (json == null) return null;
    return (jsonDecode(json) as List<dynamic>).cast<String>();
  }

  Future<List<int>?> loadIntList(String key) async {
    final json = await _loadValue(key);
    if (json == null) return null;
    return (jsonDecode(json) as List<dynamic>).cast<int>();
  }

  Future<int?> loadInt(String key) async {
    final json = await _loadValue(key);
    if (json == null) return null;
    return (jsonDecode(json) as num).toInt();
  }

  Future<double?> loadDouble(String key) async {
    final json = await _loadValue(key);
    if (json == null) return null;
    return (jsonDecode(json) as num).toDouble();
  }

  Future<bool?> loadBool(String key) async {
    final json = await _loadValue(key);
    if (json == null) return null;
    return jsonDecode(json) as bool;
  }

  Future<DateTime?> loadDateTime(String key) async {
    final json = await _loadValue(key);
    if (json == null) return null;
    final millis = (jsonDecode(json) as num).toInt();
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<T?> loadObject<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final json = await _loadValue(key);
    if (json == null) return null;
    return fromJson(jsonDecode(json));
  }

  Future<Iterable<T>?> loadObjectList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final json = await _loadValue(key);
    if (json == null) return null;
    return (jsonDecode(json) as List<dynamic>).cast<Map<String, dynamic>>().map(
      (e) => fromJson(e),
    );
  }

  Future<Iterable<String>> keys() async {
    return (await _db.managers.keyValueTable.get()).map((kv) => kv.key);
  }

  Future<String?> _loadValue(String key) async {
    Log.trace("loading value: $key");
    return (await _db.managers.keyValueTable
            .filter((kv) => kv.key(key))
            .getSingleOrNull())
        ?.value;
  }
}
