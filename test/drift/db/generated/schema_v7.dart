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
  late final GeneratedColumn<String> coverId = GeneratedColumn<String>(
      'cover_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<String> childModelJson = GeneratedColumn<String>(
      'child_model_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, playlistId, index, songId, coverId, childModelJson];
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
      coverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_id']),
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
  final String? coverId;
  final String childModelJson;
  const PlaylistSongData(
      {required this.id,
      required this.playlistId,
      required this.index,
      required this.songId,
      this.coverId,
      required this.childModelJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['playlist_id'] = Variable<String>(playlistId);
    map['index'] = Variable<int>(index);
    map['song_id'] = Variable<String>(songId);
    if (!nullToAbsent || coverId != null) {
      map['cover_id'] = Variable<String>(coverId);
    }
    map['child_model_json'] = Variable<String>(childModelJson);
    return map;
  }

  PlaylistSongCompanion toCompanion(bool nullToAbsent) {
    return PlaylistSongCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      index: Value(index),
      songId: Value(songId),
      coverId: coverId == null && nullToAbsent
          ? const Value.absent()
          : Value(coverId),
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
      coverId: serializer.fromJson<String?>(json['coverId']),
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
      'coverId': serializer.toJson<String?>(coverId),
      'childModelJson': serializer.toJson<String>(childModelJson),
    };
  }

  PlaylistSongData copyWith(
          {int? id,
          String? playlistId,
          int? index,
          String? songId,
          Value<String?> coverId = const Value.absent(),
          String? childModelJson}) =>
      PlaylistSongData(
        id: id ?? this.id,
        playlistId: playlistId ?? this.playlistId,
        index: index ?? this.index,
        songId: songId ?? this.songId,
        coverId: coverId.present ? coverId.value : this.coverId,
        childModelJson: childModelJson ?? this.childModelJson,
      );
  PlaylistSongData copyWithCompanion(PlaylistSongCompanion data) {
    return PlaylistSongData(
      id: data.id.present ? data.id.value : this.id,
      playlistId:
          data.playlistId.present ? data.playlistId.value : this.playlistId,
      index: data.index.present ? data.index.value : this.index,
      songId: data.songId.present ? data.songId.value : this.songId,
      coverId: data.coverId.present ? data.coverId.value : this.coverId,
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
          ..write('coverId: $coverId, ')
          ..write('childModelJson: $childModelJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, playlistId, index, songId, coverId, childModelJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistSongData &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.index == this.index &&
          other.songId == this.songId &&
          other.coverId == this.coverId &&
          other.childModelJson == this.childModelJson);
}

class PlaylistSongCompanion extends UpdateCompanion<PlaylistSongData> {
  final Value<int> id;
  final Value<String> playlistId;
  final Value<int> index;
  final Value<String> songId;
  final Value<String?> coverId;
  final Value<String> childModelJson;
  const PlaylistSongCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.index = const Value.absent(),
    this.songId = const Value.absent(),
    this.coverId = const Value.absent(),
    this.childModelJson = const Value.absent(),
  });
  PlaylistSongCompanion.insert({
    this.id = const Value.absent(),
    required String playlistId,
    required int index,
    required String songId,
    this.coverId = const Value.absent(),
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
    Expression<String>? coverId,
    Expression<String>? childModelJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (index != null) 'index': index,
      if (songId != null) 'song_id': songId,
      if (coverId != null) 'cover_id': coverId,
      if (childModelJson != null) 'child_model_json': childModelJson,
    });
  }

  PlaylistSongCompanion copyWith(
      {Value<int>? id,
      Value<String>? playlistId,
      Value<int>? index,
      Value<String>? songId,
      Value<String?>? coverId,
      Value<String>? childModelJson}) {
    return PlaylistSongCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      index: index ?? this.index,
      songId: songId ?? this.songId,
      coverId: coverId ?? this.coverId,
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
    if (coverId.present) {
      map['cover_id'] = Variable<String>(coverId.value);
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
          ..write('coverId: $coverId, ')
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

class Favorites extends Table with TableInfo<Favorites, FavoritesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Favorites(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<DateTime> starred = GeneratedColumn<DateTime>(
      'starred', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, starred, type];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  Set<GeneratedColumn> get $primaryKey => {id, type};
  @override
  FavoritesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoritesData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      starred: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}starred'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
    );
  }

  @override
  Favorites createAlias(String alias) {
    return Favorites(attachedDatabase, alias);
  }
}

class FavoritesData extends DataClass implements Insertable<FavoritesData> {
  final String id;
  final DateTime starred;
  final String type;
  const FavoritesData(
      {required this.id, required this.starred, required this.type});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['starred'] = Variable<DateTime>(starred);
    map['type'] = Variable<String>(type);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(
      id: Value(id),
      starred: Value(starred),
      type: Value(type),
    );
  }

  factory FavoritesData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoritesData(
      id: serializer.fromJson<String>(json['id']),
      starred: serializer.fromJson<DateTime>(json['starred']),
      type: serializer.fromJson<String>(json['type']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'starred': serializer.toJson<DateTime>(starred),
      'type': serializer.toJson<String>(type),
    };
  }

  FavoritesData copyWith({String? id, DateTime? starred, String? type}) =>
      FavoritesData(
        id: id ?? this.id,
        starred: starred ?? this.starred,
        type: type ?? this.type,
      );
  FavoritesData copyWithCompanion(FavoritesCompanion data) {
    return FavoritesData(
      id: data.id.present ? data.id.value : this.id,
      starred: data.starred.present ? data.starred.value : this.starred,
      type: data.type.present ? data.type.value : this.type,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesData(')
          ..write('id: $id, ')
          ..write('starred: $starred, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, starred, type);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoritesData &&
          other.id == this.id &&
          other.starred == this.starred &&
          other.type == this.type);
}

class FavoritesCompanion extends UpdateCompanion<FavoritesData> {
  final Value<String> id;
  final Value<DateTime> starred;
  final Value<String> type;
  final Value<int> rowid;
  const FavoritesCompanion({
    this.id = const Value.absent(),
    this.starred = const Value.absent(),
    this.type = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoritesCompanion.insert({
    required String id,
    required DateTime starred,
    required String type,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        starred = Value(starred),
        type = Value(type);
  static Insertable<FavoritesData> custom({
    Expression<String>? id,
    Expression<DateTime>? starred,
    Expression<String>? type,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (starred != null) 'starred': starred,
      if (type != null) 'type': type,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoritesCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? starred,
      Value<String>? type,
      Value<int>? rowid}) {
    return FavoritesCompanion(
      id: id ?? this.id,
      starred: starred ?? this.starred,
      type: type ?? this.type,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (starred.present) {
      map['starred'] = Variable<DateTime>(starred.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('id: $id, ')
          ..write('starred: $starred, ')
          ..write('type: $type, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class LogMessage extends Table with TableInfo<LogMessage, LogMessageData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LogMessage(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  late final GeneratedColumn<DateTime> sessionStartTime =
      GeneratedColumn<DateTime>('session_start_time', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  late final GeneratedColumn<DateTime> time = GeneratedColumn<DateTime>(
      'time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
      'level', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
      'tag', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
      'message', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> stackTrace = GeneratedColumn<String>(
      'stack_trace', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> exception = GeneratedColumn<String>(
      'exception', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, sessionStartTime, time, level, tag, message, stackTrace, exception];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'log_message';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LogMessageData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LogMessageData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sessionStartTime: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}session_start_time'])!,
      time: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}time'])!,
      level: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}level'])!,
      tag: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag'])!,
      message: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message'])!,
      stackTrace: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stack_trace'])!,
      exception: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exception']),
    );
  }

  @override
  LogMessage createAlias(String alias) {
    return LogMessage(attachedDatabase, alias);
  }
}

class LogMessageData extends DataClass implements Insertable<LogMessageData> {
  final int id;
  final DateTime sessionStartTime;
  final DateTime time;
  final String level;
  final String tag;
  final String message;
  final String stackTrace;
  final String? exception;
  const LogMessageData(
      {required this.id,
      required this.sessionStartTime,
      required this.time,
      required this.level,
      required this.tag,
      required this.message,
      required this.stackTrace,
      this.exception});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_start_time'] = Variable<DateTime>(sessionStartTime);
    map['time'] = Variable<DateTime>(time);
    map['level'] = Variable<String>(level);
    map['tag'] = Variable<String>(tag);
    map['message'] = Variable<String>(message);
    map['stack_trace'] = Variable<String>(stackTrace);
    if (!nullToAbsent || exception != null) {
      map['exception'] = Variable<String>(exception);
    }
    return map;
  }

  LogMessageCompanion toCompanion(bool nullToAbsent) {
    return LogMessageCompanion(
      id: Value(id),
      sessionStartTime: Value(sessionStartTime),
      time: Value(time),
      level: Value(level),
      tag: Value(tag),
      message: Value(message),
      stackTrace: Value(stackTrace),
      exception: exception == null && nullToAbsent
          ? const Value.absent()
          : Value(exception),
    );
  }

  factory LogMessageData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LogMessageData(
      id: serializer.fromJson<int>(json['id']),
      sessionStartTime: serializer.fromJson<DateTime>(json['sessionStartTime']),
      time: serializer.fromJson<DateTime>(json['time']),
      level: serializer.fromJson<String>(json['level']),
      tag: serializer.fromJson<String>(json['tag']),
      message: serializer.fromJson<String>(json['message']),
      stackTrace: serializer.fromJson<String>(json['stackTrace']),
      exception: serializer.fromJson<String?>(json['exception']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionStartTime': serializer.toJson<DateTime>(sessionStartTime),
      'time': serializer.toJson<DateTime>(time),
      'level': serializer.toJson<String>(level),
      'tag': serializer.toJson<String>(tag),
      'message': serializer.toJson<String>(message),
      'stackTrace': serializer.toJson<String>(stackTrace),
      'exception': serializer.toJson<String?>(exception),
    };
  }

  LogMessageData copyWith(
          {int? id,
          DateTime? sessionStartTime,
          DateTime? time,
          String? level,
          String? tag,
          String? message,
          String? stackTrace,
          Value<String?> exception = const Value.absent()}) =>
      LogMessageData(
        id: id ?? this.id,
        sessionStartTime: sessionStartTime ?? this.sessionStartTime,
        time: time ?? this.time,
        level: level ?? this.level,
        tag: tag ?? this.tag,
        message: message ?? this.message,
        stackTrace: stackTrace ?? this.stackTrace,
        exception: exception.present ? exception.value : this.exception,
      );
  LogMessageData copyWithCompanion(LogMessageCompanion data) {
    return LogMessageData(
      id: data.id.present ? data.id.value : this.id,
      sessionStartTime: data.sessionStartTime.present
          ? data.sessionStartTime.value
          : this.sessionStartTime,
      time: data.time.present ? data.time.value : this.time,
      level: data.level.present ? data.level.value : this.level,
      tag: data.tag.present ? data.tag.value : this.tag,
      message: data.message.present ? data.message.value : this.message,
      stackTrace:
          data.stackTrace.present ? data.stackTrace.value : this.stackTrace,
      exception: data.exception.present ? data.exception.value : this.exception,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LogMessageData(')
          ..write('id: $id, ')
          ..write('sessionStartTime: $sessionStartTime, ')
          ..write('time: $time, ')
          ..write('level: $level, ')
          ..write('tag: $tag, ')
          ..write('message: $message, ')
          ..write('stackTrace: $stackTrace, ')
          ..write('exception: $exception')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, sessionStartTime, time, level, tag, message, stackTrace, exception);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LogMessageData &&
          other.id == this.id &&
          other.sessionStartTime == this.sessionStartTime &&
          other.time == this.time &&
          other.level == this.level &&
          other.tag == this.tag &&
          other.message == this.message &&
          other.stackTrace == this.stackTrace &&
          other.exception == this.exception);
}

class LogMessageCompanion extends UpdateCompanion<LogMessageData> {
  final Value<int> id;
  final Value<DateTime> sessionStartTime;
  final Value<DateTime> time;
  final Value<String> level;
  final Value<String> tag;
  final Value<String> message;
  final Value<String> stackTrace;
  final Value<String?> exception;
  const LogMessageCompanion({
    this.id = const Value.absent(),
    this.sessionStartTime = const Value.absent(),
    this.time = const Value.absent(),
    this.level = const Value.absent(),
    this.tag = const Value.absent(),
    this.message = const Value.absent(),
    this.stackTrace = const Value.absent(),
    this.exception = const Value.absent(),
  });
  LogMessageCompanion.insert({
    this.id = const Value.absent(),
    required DateTime sessionStartTime,
    required DateTime time,
    required String level,
    required String tag,
    required String message,
    required String stackTrace,
    this.exception = const Value.absent(),
  })  : sessionStartTime = Value(sessionStartTime),
        time = Value(time),
        level = Value(level),
        tag = Value(tag),
        message = Value(message),
        stackTrace = Value(stackTrace);
  static Insertable<LogMessageData> custom({
    Expression<int>? id,
    Expression<DateTime>? sessionStartTime,
    Expression<DateTime>? time,
    Expression<String>? level,
    Expression<String>? tag,
    Expression<String>? message,
    Expression<String>? stackTrace,
    Expression<String>? exception,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionStartTime != null) 'session_start_time': sessionStartTime,
      if (time != null) 'time': time,
      if (level != null) 'level': level,
      if (tag != null) 'tag': tag,
      if (message != null) 'message': message,
      if (stackTrace != null) 'stack_trace': stackTrace,
      if (exception != null) 'exception': exception,
    });
  }

  LogMessageCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? sessionStartTime,
      Value<DateTime>? time,
      Value<String>? level,
      Value<String>? tag,
      Value<String>? message,
      Value<String>? stackTrace,
      Value<String?>? exception}) {
    return LogMessageCompanion(
      id: id ?? this.id,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      time: time ?? this.time,
      level: level ?? this.level,
      tag: tag ?? this.tag,
      message: message ?? this.message,
      stackTrace: stackTrace ?? this.stackTrace,
      exception: exception ?? this.exception,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionStartTime.present) {
      map['session_start_time'] = Variable<DateTime>(sessionStartTime.value);
    }
    if (time.present) {
      map['time'] = Variable<DateTime>(time.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (stackTrace.present) {
      map['stack_trace'] = Variable<String>(stackTrace.value);
    }
    if (exception.present) {
      map['exception'] = Variable<String>(exception.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LogMessageCompanion(')
          ..write('id: $id, ')
          ..write('sessionStartTime: $sessionStartTime, ')
          ..write('time: $time, ')
          ..write('level: $level, ')
          ..write('tag: $tag, ')
          ..write('message: $message, ')
          ..write('stackTrace: $stackTrace, ')
          ..write('exception: $exception')
          ..write(')'))
        .toString();
  }
}

class CoverCache extends Table with TableInfo<CoverCache, CoverCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CoverCache(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> coverId = GeneratedColumn<String>(
      'cover_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
      'size', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  late final GeneratedColumn<bool> fileFullyWritten = GeneratedColumn<bool>(
      'file_fully_written', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("file_fully_written" IN (0, 1))'));
  late final GeneratedColumn<DateTime> downloadTime = GeneratedColumn<DateTime>(
      'download_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  late final GeneratedColumn<DateTime> validTill = GeneratedColumn<DateTime>(
      'valid_till', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  late final GeneratedColumn<int> fileSizeKB = GeneratedColumn<int>(
      'file_size_k_b', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [coverId, size, fileFullyWritten, downloadTime, validTill, fileSizeKB];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cover_cache';
  @override
  Set<GeneratedColumn> get $primaryKey => {coverId, size};
  @override
  CoverCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoverCacheData(
      coverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_id'])!,
      size: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size'])!,
      fileFullyWritten: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}file_fully_written'])!,
      downloadTime: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}download_time'])!,
      validTill: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}valid_till'])!,
      fileSizeKB: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size_k_b'])!,
    );
  }

  @override
  CoverCache createAlias(String alias) {
    return CoverCache(attachedDatabase, alias);
  }
}

class CoverCacheData extends DataClass implements Insertable<CoverCacheData> {
  final String coverId;
  final int size;
  final bool fileFullyWritten;
  final DateTime downloadTime;
  final DateTime validTill;
  final int fileSizeKB;
  const CoverCacheData(
      {required this.coverId,
      required this.size,
      required this.fileFullyWritten,
      required this.downloadTime,
      required this.validTill,
      required this.fileSizeKB});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cover_id'] = Variable<String>(coverId);
    map['size'] = Variable<int>(size);
    map['file_fully_written'] = Variable<bool>(fileFullyWritten);
    map['download_time'] = Variable<DateTime>(downloadTime);
    map['valid_till'] = Variable<DateTime>(validTill);
    map['file_size_k_b'] = Variable<int>(fileSizeKB);
    return map;
  }

  CoverCacheCompanion toCompanion(bool nullToAbsent) {
    return CoverCacheCompanion(
      coverId: Value(coverId),
      size: Value(size),
      fileFullyWritten: Value(fileFullyWritten),
      downloadTime: Value(downloadTime),
      validTill: Value(validTill),
      fileSizeKB: Value(fileSizeKB),
    );
  }

  factory CoverCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CoverCacheData(
      coverId: serializer.fromJson<String>(json['coverId']),
      size: serializer.fromJson<int>(json['size']),
      fileFullyWritten: serializer.fromJson<bool>(json['fileFullyWritten']),
      downloadTime: serializer.fromJson<DateTime>(json['downloadTime']),
      validTill: serializer.fromJson<DateTime>(json['validTill']),
      fileSizeKB: serializer.fromJson<int>(json['fileSizeKB']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'coverId': serializer.toJson<String>(coverId),
      'size': serializer.toJson<int>(size),
      'fileFullyWritten': serializer.toJson<bool>(fileFullyWritten),
      'downloadTime': serializer.toJson<DateTime>(downloadTime),
      'validTill': serializer.toJson<DateTime>(validTill),
      'fileSizeKB': serializer.toJson<int>(fileSizeKB),
    };
  }

  CoverCacheData copyWith(
          {String? coverId,
          int? size,
          bool? fileFullyWritten,
          DateTime? downloadTime,
          DateTime? validTill,
          int? fileSizeKB}) =>
      CoverCacheData(
        coverId: coverId ?? this.coverId,
        size: size ?? this.size,
        fileFullyWritten: fileFullyWritten ?? this.fileFullyWritten,
        downloadTime: downloadTime ?? this.downloadTime,
        validTill: validTill ?? this.validTill,
        fileSizeKB: fileSizeKB ?? this.fileSizeKB,
      );
  CoverCacheData copyWithCompanion(CoverCacheCompanion data) {
    return CoverCacheData(
      coverId: data.coverId.present ? data.coverId.value : this.coverId,
      size: data.size.present ? data.size.value : this.size,
      fileFullyWritten: data.fileFullyWritten.present
          ? data.fileFullyWritten.value
          : this.fileFullyWritten,
      downloadTime: data.downloadTime.present
          ? data.downloadTime.value
          : this.downloadTime,
      validTill: data.validTill.present ? data.validTill.value : this.validTill,
      fileSizeKB:
          data.fileSizeKB.present ? data.fileSizeKB.value : this.fileSizeKB,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoverCacheData(')
          ..write('coverId: $coverId, ')
          ..write('size: $size, ')
          ..write('fileFullyWritten: $fileFullyWritten, ')
          ..write('downloadTime: $downloadTime, ')
          ..write('validTill: $validTill, ')
          ..write('fileSizeKB: $fileSizeKB')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      coverId, size, fileFullyWritten, downloadTime, validTill, fileSizeKB);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoverCacheData &&
          other.coverId == this.coverId &&
          other.size == this.size &&
          other.fileFullyWritten == this.fileFullyWritten &&
          other.downloadTime == this.downloadTime &&
          other.validTill == this.validTill &&
          other.fileSizeKB == this.fileSizeKB);
}

class CoverCacheCompanion extends UpdateCompanion<CoverCacheData> {
  final Value<String> coverId;
  final Value<int> size;
  final Value<bool> fileFullyWritten;
  final Value<DateTime> downloadTime;
  final Value<DateTime> validTill;
  final Value<int> fileSizeKB;
  final Value<int> rowid;
  const CoverCacheCompanion({
    this.coverId = const Value.absent(),
    this.size = const Value.absent(),
    this.fileFullyWritten = const Value.absent(),
    this.downloadTime = const Value.absent(),
    this.validTill = const Value.absent(),
    this.fileSizeKB = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CoverCacheCompanion.insert({
    required String coverId,
    required int size,
    required bool fileFullyWritten,
    required DateTime downloadTime,
    required DateTime validTill,
    required int fileSizeKB,
    this.rowid = const Value.absent(),
  })  : coverId = Value(coverId),
        size = Value(size),
        fileFullyWritten = Value(fileFullyWritten),
        downloadTime = Value(downloadTime),
        validTill = Value(validTill),
        fileSizeKB = Value(fileSizeKB);
  static Insertable<CoverCacheData> custom({
    Expression<String>? coverId,
    Expression<int>? size,
    Expression<bool>? fileFullyWritten,
    Expression<DateTime>? downloadTime,
    Expression<DateTime>? validTill,
    Expression<int>? fileSizeKB,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (coverId != null) 'cover_id': coverId,
      if (size != null) 'size': size,
      if (fileFullyWritten != null) 'file_fully_written': fileFullyWritten,
      if (downloadTime != null) 'download_time': downloadTime,
      if (validTill != null) 'valid_till': validTill,
      if (fileSizeKB != null) 'file_size_k_b': fileSizeKB,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CoverCacheCompanion copyWith(
      {Value<String>? coverId,
      Value<int>? size,
      Value<bool>? fileFullyWritten,
      Value<DateTime>? downloadTime,
      Value<DateTime>? validTill,
      Value<int>? fileSizeKB,
      Value<int>? rowid}) {
    return CoverCacheCompanion(
      coverId: coverId ?? this.coverId,
      size: size ?? this.size,
      fileFullyWritten: fileFullyWritten ?? this.fileFullyWritten,
      downloadTime: downloadTime ?? this.downloadTime,
      validTill: validTill ?? this.validTill,
      fileSizeKB: fileSizeKB ?? this.fileSizeKB,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (coverId.present) {
      map['cover_id'] = Variable<String>(coverId.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (fileFullyWritten.present) {
      map['file_fully_written'] = Variable<bool>(fileFullyWritten.value);
    }
    if (downloadTime.present) {
      map['download_time'] = Variable<DateTime>(downloadTime.value);
    }
    if (validTill.present) {
      map['valid_till'] = Variable<DateTime>(validTill.value);
    }
    if (fileSizeKB.present) {
      map['file_size_k_b'] = Variable<int>(fileSizeKB.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoverCacheCompanion(')
          ..write('coverId: $coverId, ')
          ..write('size: $size, ')
          ..write('fileFullyWritten: $fileFullyWritten, ')
          ..write('downloadTime: $downloadTime, ')
          ..write('validTill: $validTill, ')
          ..write('fileSizeKB: $fileSizeKB, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DatabaseAtV7 extends GeneratedDatabase {
  DatabaseAtV7(QueryExecutor e) : super(e);
  late final KeyValue keyValue = KeyValue(this);
  late final Scrobble scrobble = Scrobble(this);
  late final Playlist playlist = Playlist(this);
  late final PlaylistSong playlistSong = PlaylistSong(this);
  late final DownloadTask downloadTask = DownloadTask(this);
  late final Favorites favorites = Favorites(this);
  late final LogMessage logMessage = LogMessage(this);
  late final CoverCache coverCache = CoverCache(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        keyValue,
        scrobble,
        playlist,
        playlistSong,
        downloadTask,
        favorites,
        logMessage,
        coverCache
      ];
  @override
  int get schemaVersion => 7;
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}
