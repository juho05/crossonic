import 'dart:convert';

import 'package:crossonic/data/services/database/database.dart';
import 'package:drift/drift.dart';

class KeyValueRepository {
  final Database _db;

  KeyValueRepository({required Database database}) : _db = database;

  Future<void> store<T>(String key, T value) async {
    await _db.managers.keyValue.create(
      (o) => o(key: key, value: jsonEncode(value)),
      mode: InsertMode.replace,
    );
  }

  Future<void> remove(String key) async {
    await _db.managers.keyValue.filter((kv) => kv.key(key)).delete();
  }

  Future<String?> loadString(String key) async {
    final json = await _loadValue(key);
    if (json == null) return null;
    return jsonDecode(json) as String;
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

  Future<T?> loadObject<T>(
      String key, T Function(Map<String, dynamic>) fromJson) async {
    final json = await _loadValue(key);
    if (json == null) return null;
    return fromJson(jsonDecode(json));
  }

  Future<Iterable<T>?> loadObjectList<T>(
      String key, T Function(Map<String, dynamic>) fromJson) async {
    final json = await _loadValue(key);
    if (json == null) return null;
    return (jsonDecode(json) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((e) => fromJson(e));
  }

  Future<String?> _loadValue(String key) async {
    return (await _db.managers.keyValue
            .filter((kv) => kv.key(key))
            .getSingleOrNull())
        ?.value;
  }
}
