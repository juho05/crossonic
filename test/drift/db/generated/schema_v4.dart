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

class Playlist extends Table with TableInfo<Playlist, PlaylistData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Playlist(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
      'comment', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<int> songCount = GeneratedColumn<int>(
      'song_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  late final GeneratedColumn<DateTime> created = GeneratedColumn<DateTime>(
      'created', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  late final GeneratedColumn<DateTime> changed = GeneratedColumn<DateTime>(
      'changed', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  late final GeneratedColumn<String> coverArt = GeneratedColumn<String>(
      'cover_art', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<bool> download = GeneratedColumn<bool>(
      'download', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("download" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        comment,
        songCount,
        durationMs,
        created,
        changed,
        coverArt,
        download
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaylistData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      comment: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}comment']),
      songCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}song_count'])!,
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms'])!,
      created: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created'])!,
      changed: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}changed'])!,
      coverArt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_art']),
      download: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}download'])!,
    );
  }

  @override
  Playlist createAlias(String alias) {
    return Playlist(attachedDatabase, alias);
  }
}

class PlaylistData extends DataClass implements Insertable<PlaylistData> {
  final String id;
  final String name;
  final String? comment;
  final int songCount;
  final int durationMs;
  final DateTime created;
  final DateTime changed;
  final String? coverArt;
  final bool download;
  const PlaylistData(
      {required this.id,
      required this.name,
      this.comment,
      required this.songCount,
      required this.durationMs,
      required this.created,
      required this.changed,
      this.coverArt,
      required this.download});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || comment != null) {
      map['comment'] = Variable<String>(comment);
    }
    map['song_count'] = Variable<int>(songCount);
    map['duration_ms'] = Variable<int>(durationMs);
    map['created'] = Variable<DateTime>(created);
    map['changed'] = Variable<DateTime>(changed);
    if (!nullToAbsent || coverArt != null) {
      map['cover_art'] = Variable<String>(coverArt);
    }
    map['download'] = Variable<bool>(download);
    return map;
  }

  PlaylistCompanion toCompanion(bool nullToAbsent) {
    return PlaylistCompanion(
      id: Value(id),
      name: Value(name),
      comment: comment == null && nullToAbsent
          ? const Value.absent()
          : Value(comment),
      songCount: Value(songCount),
      durationMs: Value(durationMs),
      created: Value(created),
      changed: Value(changed),
      coverArt: coverArt == null && nullToAbsent
          ? const Value.absent()
          : Value(coverArt),
      download: Value(download),
    );
  }

  factory PlaylistData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      comment: serializer.fromJson<String?>(json['comment']),
      songCount: serializer.fromJson<int>(json['songCount']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      created: serializer.fromJson<DateTime>(json['created']),
      changed: serializer.fromJson<DateTime>(json['changed']),
      coverArt: serializer.fromJson<String?>(json['coverArt']),
      download: serializer.fromJson<bool>(json['download']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'comment': serializer.toJson<String?>(comment),
      'songCount': serializer.toJson<int>(songCount),
      'durationMs': serializer.toJson<int>(durationMs),
      'created': serializer.toJson<DateTime>(created),
      'changed': serializer.toJson<DateTime>(changed),
      'coverArt': serializer.toJson<String?>(coverArt),
      'download': serializer.toJson<bool>(download),
    };
  }

  PlaylistData copyWith(
          {String? id,
          String? name,
          Value<String?> comment = const Value.absent(),
          int? songCount,
          int? durationMs,
          DateTime? created,
          DateTime? changed,
          Value<String?> coverArt = const Value.absent(),
          bool? download}) =>
      PlaylistData(
        id: id ?? this.id,
        name: name ?? this.name,
        comment: comment.present ? comment.value : this.comment,
        songCount: songCount ?? this.songCount,
        durationMs: durationMs ?? this.durationMs,
        created: created ?? this.created,
        changed: changed ?? this.changed,
        coverArt: coverArt.present ? coverArt.value : this.coverArt,
        download: download ?? this.download,
      );
  PlaylistData copyWithCompanion(PlaylistCompanion data) {
    return PlaylistData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      comment: data.comment.present ? data.comment.value : this.comment,
      songCount: data.songCount.present ? data.songCount.value : this.songCount,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      created: data.created.present ? data.created.value : this.created,
      changed: data.changed.present ? data.changed.value : this.changed,
      coverArt: data.coverArt.present ? data.coverArt.value : this.coverArt,
      download: data.download.present ? data.download.value : this.download,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('comment: $comment, ')
          ..write('songCount: $songCount, ')
          ..write('durationMs: $durationMs, ')
          ..write('created: $created, ')
          ..write('changed: $changed, ')
          ..write('coverArt: $coverArt, ')
          ..write('download: $download')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, comment, songCount, durationMs,
      created, changed, coverArt, download);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistData &&
          other.id == this.id &&
          other.name == this.name &&
          other.comment == this.comment &&
          other.songCount == this.songCount &&
          other.durationMs == this.durationMs &&
          other.created == this.created &&
          other.changed == this.changed &&
          other.coverArt == this.coverArt &&
          other.download == this.download);
}

class PlaylistCompanion extends UpdateCompanion<PlaylistData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> comment;
  final Value<int> songCount;
  final Value<int> durationMs;
  final Value<DateTime> created;
  final Value<DateTime> changed;
  final Value<String?> coverArt;
  final Value<bool> download;
  final Value<int> rowid;
  const PlaylistCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.comment = const Value.absent(),
    this.songCount = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.created = const Value.absent(),
    this.changed = const Value.absent(),
    this.coverArt = const Value.absent(),
    this.download = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistCompanion.insert({
    required String id,
    required String name,
    this.comment = const Value.absent(),
    required int songCount,
    required int durationMs,
    required DateTime created,
    required DateTime changed,
    this.coverArt = const Value.absent(),
    this.download = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        songCount = Value(songCount),
        durationMs = Value(durationMs),
        created = Value(created),
        changed = Value(changed);
  static Insertable<PlaylistData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? comment,
    Expression<int>? songCount,
    Expression<int>? durationMs,
    Expression<DateTime>? created,
    Expression<DateTime>? changed,
    Expression<String>? coverArt,
    Expression<bool>? download,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (comment != null) 'comment': comment,
      if (songCount != null) 'song_count': songCount,
      if (durationMs != null) 'duration_ms': durationMs,
      if (created != null) 'created': created,
      if (changed != null) 'changed': changed,
      if (coverArt != null) 'cover_art': coverArt,
      if (download != null) 'download': download,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? comment,
      Value<int>? songCount,
      Value<int>? durationMs,
      Value<DateTime>? created,
      Value<DateTime>? changed,
      Value<String?>? coverArt,
      Value<bool>? download,
      Value<int>? rowid}) {
    return PlaylistCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      comment: comment ?? this.comment,
      songCount: songCount ?? this.songCount,
      durationMs: durationMs ?? this.durationMs,
      created: created ?? this.created,
      changed: changed ?? this.changed,
      coverArt: coverArt ?? this.coverArt,
      download: download ?? this.download,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    if (songCount.present) {
      map['song_count'] = Variable<int>(songCount.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (created.present) {
      map['created'] = Variable<DateTime>(created.value);
    }
    if (changed.present) {
      map['changed'] = Variable<DateTime>(changed.value);
    }
    if (coverArt.present) {
      map['cover_art'] = Variable<String>(coverArt.value);
    }
    if (download.present) {
      map['download'] = Variable<bool>(download.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('comment: $comment, ')
          ..write('songCount: $songCount, ')
          ..write('durationMs: $durationMs, ')
          ..write('created: $created, ')
          ..write('changed: $changed, ')
          ..write('coverArt: $coverArt, ')
          ..write('download: $download, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class PlaylistSong extends Table
    with TableInfo<PlaylistSong, PlaylistSongData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  PlaylistSong(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
      'playlist_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES playlist (id) ON DELETE CASCADE'));
  late final GeneratedColumn<int> index = GeneratedColumn<int>(
      'index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  late final GeneratedColumn<String> songId = GeneratedColumn<String>(
      'song_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> childModelJson = GeneratedColumn<String>(
      'child_model_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, playlistId, index, songId, childModelJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_song';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaylistSongData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistSongData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      playlistId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}playlist_id'])!,
      index: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}index'])!,
      songId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}song_id'])!,
      childModelJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}child_model_json'])!,
    );
  }

  @override
  PlaylistSong createAlias(String alias) {
    return PlaylistSong(attachedDatabase, alias);
  }
}

class PlaylistSongData extends DataClass
    implements Insertable<PlaylistSongData> {
  final int id;
  final String playlistId;
  final int index;
  final String songId;
  final String childModelJson;
  const PlaylistSongData(
      {required this.id,
      required this.playlistId,
      required this.index,
      required this.songId,
      required this.childModelJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['playlist_id'] = Variable<String>(playlistId);
    map['index'] = Variable<int>(index);
    map['song_id'] = Variable<String>(songId);
    map['child_model_json'] = Variable<String>(childModelJson);
    return map;
  }

  PlaylistSongCompanion toCompanion(bool nullToAbsent) {
    return PlaylistSongCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      index: Value(index),
      songId: Value(songId),
      childModelJson: Value(childModelJson),
    );
  }

  factory PlaylistSongData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistSongData(
      id: serializer.fromJson<int>(json['id']),
      playlistId: serializer.fromJson<String>(json['playlistId']),
      index: serializer.fromJson<int>(json['index']),
      songId: serializer.fromJson<String>(json['songId']),
      childModelJson: serializer.fromJson<String>(json['childModelJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playlistId': serializer.toJson<String>(playlistId),
      'index': serializer.toJson<int>(index),
      'songId': serializer.toJson<String>(songId),
      'childModelJson': serializer.toJson<String>(childModelJson),
    };
  }

  PlaylistSongData copyWith(
          {int? id,
          String? playlistId,
          int? index,
          String? songId,
          String? childModelJson}) =>
      PlaylistSongData(
        id: id ?? this.id,
        playlistId: playlistId ?? this.playlistId,
        index: index ?? this.index,
        songId: songId ?? this.songId,
        childModelJson: childModelJson ?? this.childModelJson,
      );
  PlaylistSongData copyWithCompanion(PlaylistSongCompanion data) {
    return PlaylistSongData(
      id: data.id.present ? data.id.value : this.id,
      playlistId:
          data.playlistId.present ? data.playlistId.value : this.playlistId,
      index: data.index.present ? data.index.value : this.index,
      songId: data.songId.present ? data.songId.value : this.songId,
      childModelJson: data.childModelJson.present
          ? data.childModelJson.value
          : this.childModelJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistSongData(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('index: $index, ')
          ..write('songId: $songId, ')
          ..write('childModelJson: $childModelJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, playlistId, index, songId, childModelJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistSongData &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.index == this.index &&
          other.songId == this.songId &&
          other.childModelJson == this.childModelJson);
}

class PlaylistSongCompanion extends UpdateCompanion<PlaylistSongData> {
  final Value<int> id;
  final Value<String> playlistId;
  final Value<int> index;
  final Value<String> songId;
  final Value<String> childModelJson;
  const PlaylistSongCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.index = const Value.absent(),
    this.songId = const Value.absent(),
    this.childModelJson = const Value.absent(),
  });
  PlaylistSongCompanion.insert({
    this.id = const Value.absent(),
    required String playlistId,
    required int index,
    required String songId,
    required String childModelJson,
  })  : playlistId = Value(playlistId),
        index = Value(index),
        songId = Value(songId),
        childModelJson = Value(childModelJson);
  static Insertable<PlaylistSongData> custom({
    Expression<int>? id,
    Expression<String>? playlistId,
    Expression<int>? index,
    Expression<String>? songId,
    Expression<String>? childModelJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (index != null) 'index': index,
      if (songId != null) 'song_id': songId,
      if (childModelJson != null) 'child_model_json': childModelJson,
    });
  }

  PlaylistSongCompanion copyWith(
      {Value<int>? id,
      Value<String>? playlistId,
      Value<int>? index,
      Value<String>? songId,
      Value<String>? childModelJson}) {
    return PlaylistSongCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      index: index ?? this.index,
      songId: songId ?? this.songId,
      childModelJson: childModelJson ?? this.childModelJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (index.present) {
      map['index'] = Variable<int>(index.value);
    }
    if (songId.present) {
      map['song_id'] = Variable<String>(songId.value);
    }
    if (childModelJson.present) {
      map['child_model_json'] = Variable<String>(childModelJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistSongCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('index: $index, ')
          ..write('songId: $songId, ')
          ..write('childModelJson: $childModelJson')
          ..write(')'))
        .toString();
  }
}

class DownloadTask extends Table
    with TableInfo<DownloadTask, DownloadTaskData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  DownloadTask(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
      'task_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> object = GeneratedColumn<String>(
      'object', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> group = GeneratedColumn<String>(
      'group', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> updated = GeneratedColumn<DateTime>(
      'updated', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [taskId, type, object, group, status, updated];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'download_task';
  @override
  Set<GeneratedColumn> get $primaryKey => {taskId, type};
  @override
  DownloadTaskData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadTaskData(
      taskId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}task_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      object: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}object'])!,
      group: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status']),
      updated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated'])!,
    );
  }

  @override
  DownloadTask createAlias(String alias) {
    return DownloadTask(attachedDatabase, alias);
  }
}

class DownloadTaskData extends DataClass
    implements Insertable<DownloadTaskData> {
  final String taskId;
  final String type;
  final String object;
  final String? group;
  final String? status;
  final DateTime updated;
  const DownloadTaskData(
      {required this.taskId,
      required this.type,
      required this.object,
      this.group,
      this.status,
      required this.updated});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task_id'] = Variable<String>(taskId);
    map['type'] = Variable<String>(type);
    map['object'] = Variable<String>(object);
    if (!nullToAbsent || group != null) {
      map['group'] = Variable<String>(group);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    map['updated'] = Variable<DateTime>(updated);
    return map;
  }

  DownloadTaskCompanion toCompanion(bool nullToAbsent) {
    return DownloadTaskCompanion(
      taskId: Value(taskId),
      type: Value(type),
      object: Value(object),
      group:
          group == null && nullToAbsent ? const Value.absent() : Value(group),
      status:
          status == null && nullToAbsent ? const Value.absent() : Value(status),
      updated: Value(updated),
    );
  }

  factory DownloadTaskData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadTaskData(
      taskId: serializer.fromJson<String>(json['taskId']),
      type: serializer.fromJson<String>(json['type']),
      object: serializer.fromJson<String>(json['object']),
      group: serializer.fromJson<String?>(json['group']),
      status: serializer.fromJson<String?>(json['status']),
      updated: serializer.fromJson<DateTime>(json['updated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'taskId': serializer.toJson<String>(taskId),
      'type': serializer.toJson<String>(type),
      'object': serializer.toJson<String>(object),
      'group': serializer.toJson<String?>(group),
      'status': serializer.toJson<String?>(status),
      'updated': serializer.toJson<DateTime>(updated),
    };
  }

  DownloadTaskData copyWith(
          {String? taskId,
          String? type,
          String? object,
          Value<String?> group = const Value.absent(),
          Value<String?> status = const Value.absent(),
          DateTime? updated}) =>
      DownloadTaskData(
        taskId: taskId ?? this.taskId,
        type: type ?? this.type,
        object: object ?? this.object,
        group: group.present ? group.value : this.group,
        status: status.present ? status.value : this.status,
        updated: updated ?? this.updated,
      );
  DownloadTaskData copyWithCompanion(DownloadTaskCompanion data) {
    return DownloadTaskData(
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      type: data.type.present ? data.type.value : this.type,
      object: data.object.present ? data.object.value : this.object,
      group: data.group.present ? data.group.value : this.group,
      status: data.status.present ? data.status.value : this.status,
      updated: data.updated.present ? data.updated.value : this.updated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadTaskData(')
          ..write('taskId: $taskId, ')
          ..write('type: $type, ')
          ..write('object: $object, ')
          ..write('group: $group, ')
          ..write('status: $status, ')
          ..write('updated: $updated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(taskId, type, object, group, status, updated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadTaskData &&
          other.taskId == this.taskId &&
          other.type == this.type &&
          other.object == this.object &&
          other.group == this.group &&
          other.status == this.status &&
          other.updated == this.updated);
}

class DownloadTaskCompanion extends UpdateCompanion<DownloadTaskData> {
  final Value<String> taskId;
  final Value<String> type;
  final Value<String> object;
  final Value<String?> group;
  final Value<String?> status;
  final Value<DateTime> updated;
  final Value<int> rowid;
  const DownloadTaskCompanion({
    this.taskId = const Value.absent(),
    this.type = const Value.absent(),
    this.object = const Value.absent(),
    this.group = const Value.absent(),
    this.status = const Value.absent(),
    this.updated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadTaskCompanion.insert({
    required String taskId,
    required String type,
    required String object,
    this.group = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime updated,
    this.rowid = const Value.absent(),
  })  : taskId = Value(taskId),
        type = Value(type),
        object = Value(object),
        updated = Value(updated);
  static Insertable<DownloadTaskData> custom({
    Expression<String>? taskId,
    Expression<String>? type,
    Expression<String>? object,
    Expression<String>? group,
    Expression<String>? status,
    Expression<DateTime>? updated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (taskId != null) 'task_id': taskId,
      if (type != null) 'type': type,
      if (object != null) 'object': object,
      if (group != null) 'group': group,
      if (status != null) 'status': status,
      if (updated != null) 'updated': updated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadTaskCompanion copyWith(
      {Value<String>? taskId,
      Value<String>? type,
      Value<String>? object,
      Value<String?>? group,
      Value<String?>? status,
      Value<DateTime>? updated,
      Value<int>? rowid}) {
    return DownloadTaskCompanion(
      taskId: taskId ?? this.taskId,
      type: type ?? this.type,
      object: object ?? this.object,
      group: group ?? this.group,
      status: status ?? this.status,
      updated: updated ?? this.updated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (object.present) {
      map['object'] = Variable<String>(object.value);
    }
    if (group.present) {
      map['group'] = Variable<String>(group.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (updated.present) {
      map['updated'] = Variable<DateTime>(updated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadTaskCompanion(')
          ..write('taskId: $taskId, ')
          ..write('type: $type, ')
          ..write('object: $object, ')
          ..write('group: $group, ')
          ..write('status: $status, ')
          ..write('updated: $updated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DatabaseAtV4 extends GeneratedDatabase {
  DatabaseAtV4(QueryExecutor e) : super(e);
  late final KeyValue keyValue = KeyValue(this);
  late final Scrobble scrobble = Scrobble(this);
  late final Playlist playlist = Playlist(this);
  late final PlaylistSong playlistSong = PlaylistSong(this);
  late final DownloadTask downloadTask = DownloadTask(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [keyValue, scrobble, playlist, playlistSong, downloadTask];
  @override
  int get schemaVersion => 4;
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}
