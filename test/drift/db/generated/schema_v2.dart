// dart format width=80
// GENERATED CODE, DO NOT EDIT BY HAND.
// ignore_for_file: type=lint
import 'package:drift/drift.dart';

class KeyValue extends Table with TableInfo<KeyValue, KeyValueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  KeyValue(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_value';
  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KeyValueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyValueData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  KeyValue createAlias(String alias) {
    return KeyValue(attachedDatabase, alias);
  }
}

class KeyValueData extends DataClass implements Insertable<KeyValueData> {
  final String key;
  final String value;
  const KeyValueData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KeyValueCompanion toCompanion(bool nullToAbsent) {
    return KeyValueCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory KeyValueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyValueData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KeyValueData copyWith({String? key, String? value}) => KeyValueData(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  KeyValueData copyWithCompanion(KeyValueCompanion data) {
    return KeyValueData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyValueData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyValueData &&
          other.key == this.key &&
          other.value == this.value);
}

class KeyValueCompanion extends UpdateCompanion<KeyValueData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KeyValueCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyValueCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<KeyValueData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyValueCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return KeyValueCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyValueCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Scrobble extends Table with TableInfo<Scrobble, ScrobbleData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Scrobble(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> songId = GeneratedColumn<String>(
      'song_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  late final GeneratedColumn<int> listenDurationMs = GeneratedColumn<int>(
      'listen_duration_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  late final GeneratedColumn<int> songDurationMs = GeneratedColumn<int>(
      'song_duration_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [songId, startTime, listenDurationMs, songDurationMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scrobble';
  @override
  Set<GeneratedColumn> get $primaryKey => {songId, startTime};
  @override
  ScrobbleData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScrobbleData(
      songId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}song_id'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      listenDurationMs: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}listen_duration_ms'])!,
      songDurationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}song_duration_ms']),
    );
  }

  @override
  Scrobble createAlias(String alias) {
    return Scrobble(attachedDatabase, alias);
  }
}

class ScrobbleData extends DataClass implements Insertable<ScrobbleData> {
  final String songId;
  final DateTime startTime;
  final int listenDurationMs;
  final int? songDurationMs;
  const ScrobbleData(
      {required this.songId,
      required this.startTime,
      required this.listenDurationMs,
      this.songDurationMs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['song_id'] = Variable<String>(songId);
    map['start_time'] = Variable<DateTime>(startTime);
    map['listen_duration_ms'] = Variable<int>(listenDurationMs);
    if (!nullToAbsent || songDurationMs != null) {
      map['song_duration_ms'] = Variable<int>(songDurationMs);
    }
    return map;
  }

  ScrobbleCompanion toCompanion(bool nullToAbsent) {
    return ScrobbleCompanion(
      songId: Value(songId),
      startTime: Value(startTime),
      listenDurationMs: Value(listenDurationMs),
      songDurationMs: songDurationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(songDurationMs),
    );
  }

  factory ScrobbleData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScrobbleData(
      songId: serializer.fromJson<String>(json['songId']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      listenDurationMs: serializer.fromJson<int>(json['listenDurationMs']),
      songDurationMs: serializer.fromJson<int?>(json['songDurationMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'songId': serializer.toJson<String>(songId),
      'startTime': serializer.toJson<DateTime>(startTime),
      'listenDurationMs': serializer.toJson<int>(listenDurationMs),
      'songDurationMs': serializer.toJson<int?>(songDurationMs),
    };
  }

  ScrobbleData copyWith(
          {String? songId,
          DateTime? startTime,
          int? listenDurationMs,
          Value<int?> songDurationMs = const Value.absent()}) =>
      ScrobbleData(
        songId: songId ?? this.songId,
        startTime: startTime ?? this.startTime,
        listenDurationMs: listenDurationMs ?? this.listenDurationMs,
        songDurationMs:
            songDurationMs.present ? songDurationMs.value : this.songDurationMs,
      );
  ScrobbleData copyWithCompanion(ScrobbleCompanion data) {
    return ScrobbleData(
      songId: data.songId.present ? data.songId.value : this.songId,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      listenDurationMs: data.listenDurationMs.present
          ? data.listenDurationMs.value
          : this.listenDurationMs,
      songDurationMs: data.songDurationMs.present
          ? data.songDurationMs.value
          : this.songDurationMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScrobbleData(')
          ..write('songId: $songId, ')
          ..write('startTime: $startTime, ')
          ..write('listenDurationMs: $listenDurationMs, ')
          ..write('songDurationMs: $songDurationMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(songId, startTime, listenDurationMs, songDurationMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScrobbleData &&
          other.songId == this.songId &&
          other.startTime == this.startTime &&
          other.listenDurationMs == this.listenDurationMs &&
          other.songDurationMs == this.songDurationMs);
}

class ScrobbleCompanion extends UpdateCompanion<ScrobbleData> {
  final Value<String> songId;
  final Value<DateTime> startTime;
  final Value<int> listenDurationMs;
  final Value<int?> songDurationMs;
  final Value<int> rowid;
  const ScrobbleCompanion({
    this.songId = const Value.absent(),
    this.startTime = const Value.absent(),
    this.listenDurationMs = const Value.absent(),
    this.songDurationMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScrobbleCompanion.insert({
    required String songId,
    required DateTime startTime,
    required int listenDurationMs,
    this.songDurationMs = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : songId = Value(songId),
        startTime = Value(startTime),
        listenDurationMs = Value(listenDurationMs);
  static Insertable<ScrobbleData> custom({
    Expression<String>? songId,
    Expression<DateTime>? startTime,
    Expression<int>? listenDurationMs,
    Expression<int>? songDurationMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (songId != null) 'song_id': songId,
      if (startTime != null) 'start_time': startTime,
      if (listenDurationMs != null) 'listen_duration_ms': listenDurationMs,
      if (songDurationMs != null) 'song_duration_ms': songDurationMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScrobbleCompanion copyWith(
      {Value<String>? songId,
      Value<DateTime>? startTime,
      Value<int>? listenDurationMs,
      Value<int?>? songDurationMs,
      Value<int>? rowid}) {
    return ScrobbleCompanion(
      songId: songId ?? this.songId,
      startTime: startTime ?? this.startTime,
      listenDurationMs: listenDurationMs ?? this.listenDurationMs,
      songDurationMs: songDurationMs ?? this.songDurationMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (songId.present) {
      map['song_id'] = Variable<String>(songId.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (listenDurationMs.present) {
      map['listen_duration_ms'] = Variable<int>(listenDurationMs.value);
    }
    if (songDurationMs.present) {
      map['song_duration_ms'] = Variable<int>(songDurationMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScrobbleCompanion(')
          ..write('songId: $songId, ')
          ..write('startTime: $startTime, ')
          ..write('listenDurationMs: $listenDurationMs, ')
          ..write('songDurationMs: $songDurationMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DatabaseAtV2 extends GeneratedDatabase {
  DatabaseAtV2(QueryExecutor e) : super(e);
  late final KeyValue keyValue = KeyValue(this);
  late final Scrobble scrobble = Scrobble(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [keyValue, scrobble];
  @override
  int get schemaVersion => 2;
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}
