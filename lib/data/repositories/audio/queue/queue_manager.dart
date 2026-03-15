import 'package:collection/collection.dart';
import 'package:crossonic/data/repositories/audio/queue/queue.dart';
import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/song/song_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/services/database/database.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

class QueueManager extends ChangeNotifier {
  static const _defaultQueueId = "crossonic_default";
  static const _currentSongIdKey = "queue_manager.current_song";
  static const _currentQueueIdKey = "queue_manager.current_queue";

  final Database _db;
  final SongRepository _songRepo;
  final KeyValueRepository _keyValue;

  final BehaviorSubject<Song?> _current = BehaviorSubject.seeded(null);

  ValueStream<Song?> get current => _current.stream;

  final BehaviorSubject<
    ({Song? current, Song? next, bool currentChanged, bool fromAdvance})
  >
  _currentAndNext = BehaviorSubject.seeded((
    current: null,
    next: null,
    currentChanged: false,
    fromAdvance: false,
  ));

  ValueStream<
    ({Song? current, Song? next, bool currentChanged, bool fromAdvance})
  >
  get currentAndNext => _currentAndNext.stream;

  final BehaviorSubject<bool> _looping = BehaviorSubject.seeded(false);

  ValueStream<bool> get looping => _looping.stream;

  String _currentQueueId = _defaultQueueId;
  String get currentQueueId => _currentQueueId;

  int _currentIndex = -1;
  int _regularLength = 0;
  int _prioLength = 0;

  QueueManager({
    required Database db,
    required SongRepository songRepo,
    required KeyValueRepository keyValue,
  }) : _db = db,
       _songRepo = songRepo,
       _keyValue = keyValue;

  Future<void> init() async {
    await _db.managers.queueTable.create(
      (o) => o(id: _defaultQueueId, name: "Default"),
      mode: InsertMode.insertOrIgnore,
    );

    _currentQueueId =
        await _keyValue.loadString(_currentQueueIdKey) ?? _defaultQueueId;

    final queue = await _db.managers.queueTable
        .filter((f) => f.id(_currentQueueId))
        .getSingle();

    _regularLength = await _db.managers.queueSongTable
        .filter((f) => f.queueId.id(_currentQueueId))
        .count();
    _prioLength = await _db.managers.priorityQueueSongTable.count();

    _currentIndex = queue.currentIndex;
    _looping.add(queue.loop);

    final currentSongId = await _keyValue.loadString(_currentSongIdKey);
    if (currentSongId != null) {
      final currentSong = await _db.managers.songTable
          .filter((f) => f.id(currentSongId))
          .getSingle();
      await _currentChanged(_songRepo.songFromDBModel(currentSong));
    }
  }

  Future<Queue> createNewQueue(String name) async {
    final id = const Uuid().v4();

    final currentQueue = _currentQueueId;

    bool? loop;
    int? currentIndex;
    final current = await _db.managers.queueTable
        .filter((f) => f.id(currentQueue))
        .getSingle();
    loop = current.loop;
    currentIndex = current.currentIndex;

    await _db.transaction(() async {
      await _db.managers.queueTable.create(
        (o) => o(
          id: id,
          name: name,
          loop: Value.absentIfNull(loop),
          currentIndex: Value.absentIfNull(currentIndex),
        ),
      );
      final idVariable = Variable(id);
      await _db
          .into(_db.queueSongTable)
          .insertFromSelect(
            _db.selectOnly(_db.queueSongTable)
              ..where(_db.queueSongTable.queueId.equals(currentQueue))
              ..addColumns([
                _db.queueSongTable.index,
                _db.queueSongTable.songId,
                idVariable,
              ]),
            columns: {
              _db.queueSongTable.queueId: idVariable,
              _db.queueSongTable.index: _db.queueSongTable.index,
              _db.queueSongTable.songId: _db.queueSongTable.songId,
            },
          );
    });

    final songCount = await _db.managers.queueTable
        .filter((f) => f.id(id))
        .count();

    await switchQueue(id, updateCurrent: false);

    return Queue(
      id: id,
      name: name,
      songCount: songCount,
      currentIndex: currentIndex ?? -1,
      isDefault: false,
    );
  }

  Future<void> switchQueue(
    String queueId, {
    bool notify = true,
    bool updateCurrent = true,
  }) async {
    final queue = await _db.managers.queueTable
        .filter((f) => f.id(queueId))
        .getSingle();
    final queueLength = await _db.managers.queueSongTable
        .filter((f) => f.queueId.id(queueId))
        .count();
    final currentSong = await _getSongAt(queue.currentIndex, queueId: queue.id);
    _currentQueueId = queue.id;
    _currentIndex = queue.currentIndex;
    _regularLength = queueLength;
    _looping.add(queue.loop);

    if (_currentQueueId != _defaultQueueId) {
      await _keyValue.store(_currentQueueIdKey, queueId);
    } else {
      await _keyValue.remove(_currentQueueIdKey);
    }

    if (updateCurrent) {
      await _currentChanged(currentSong);
    }
    if (notify) {
      notifyListeners();
    }
  }

  Future<List<Queue>> getQueues({
    String filter = "",
    int? limit,
    int offset = 0,
  }) async {
    final songCountExp = _db.queueSongTable.id.count();
    final query = _db.select(_db.queueTable).join([
      leftOuterJoin(
        _db.queueSongTable,
        _db.queueSongTable.queueId.equalsExp(_db.queueTable.id),
        useColumns: false,
      ),
    ]);
    query.addColumns([songCountExp]);
    if (filter.isNotEmpty) {
      query.where(_db.queueTable.name.contains(filter));
    }
    query.groupBy([_db.queueTable.id]);
    if (limit != null) {
      query.limit(limit, offset: offset);
    }
    query.orderBy([
      OrderingTerm(
        expression: _db.queueTable.id.equals(_defaultQueueId),
        mode: OrderingMode.desc,
      ),
      OrderingTerm.asc(_db.queueTable.name.lower()),
      OrderingTerm.asc(_db.queueTable.id),
    ]);
    final result = await query.map((row) {
      final queue = row.readTable(_db.queueTable);
      final songCount = row.read(songCountExp);
      return Queue(
        id: queue.id,
        name: queue.name,
        songCount: songCount ?? 0,
        isDefault: queue.id == _defaultQueueId,
        currentIndex: queue.currentIndex,
      );
    }).get();
    return result;
  }

  Future<void> deleteQueue(String id, {bool notify = true}) async {
    if (id == _defaultQueueId) {
      throw ArgumentError("Cannot delete default queue");
    }
    if (id == _currentQueueId) {
      await switchQueue(_defaultQueueId, updateCurrent: true, notify: false);
    }
    await _db.managers.queueTable.filter((f) => f.id(id)).delete();
    if (notify) {
      notifyListeners();
    }
  }

  Future<Queue> getCurrentQueue() async {
    final songCountExp = _db.queueSongTable.id.count();
    final query = _db.select(_db.queueTable).join([
      leftOuterJoin(
        _db.queueSongTable,
        _db.queueSongTable.queueId.equalsExp(_db.queueTable.id),
        useColumns: false,
      ),
    ]);
    query.addColumns([songCountExp]);
    query.where(_db.queueTable.id.equals(_currentQueueId));
    final result = await query.map((row) {
      final queue = row.readTable(_db.queueTable);
      final songCount = row.read(songCountExp);
      return Queue(
        id: queue.id,
        name: queue.name,
        songCount: songCount ?? 0,
        isDefault: queue.id == _defaultQueueId,
        currentIndex: queue.currentIndex,
      );
    }).getSingle();
    return result;
  }

  Future<void> add(Song song, bool priority) {
    return addAll([song], priority);
  }

  Future<void> addAll(Iterable<Song> songs, bool priority) {
    if (priority) {
      return _insertPrio(_prioLength, songs);
    } else {
      return _insert(_regularLength, songs);
    }
  }

  Future<void> insert(int index, Song song, bool priority) {
    return insertAll(index, [song], priority);
  }

  Future<void> insertAll(int index, Iterable<Song> songs, bool priority) {
    if (priority) {
      return _insertPrio(index, songs);
    } else {
      return _insert(index, songs);
    }
  }

  Future<void> _insert(int index, Iterable<Song> songs) async {
    if (songs.isEmpty) return;
    Log.trace(
      "insert ${songs.length} songs into regular queue at position $index/$_regularLength",
    );
    if (index < 0 || index > _regularLength) {
      throw IndexError.withLength(
        index,
        _regularLength,
        message: "index out of bounds",
      );
    }
    final queueId = _currentQueueId;
    await _db.transaction(() async {
      if (index < _regularLength) {
        await _db.managers.queueSongTable
            .filter(
              (f) => f.queueId.id(queueId) & f.index.isBiggerOrEqualTo(index),
            )
            .update(
              (o) => QueueSongTableCompanion.custom(
                index: _db.queueSongTable.index + Constant(songs.length),
              ),
            );
      }
      await _db.managers.queueSongTable.bulkCreate(
        (o) => songs.mapIndexed(
          (i, s) => o(index: index + i, songId: s.id, queueId: queueId),
        ),
      );
    });
    _regularLength += songs.length;
    if (current.value == null) {
      await _currentChanged(songs.first);
    } else if (_currentIndex >= index) {
      await _updateCurrentIndex(_currentIndex + songs.length);
    } else if (index == _nextIndex && _prioLength == 0) {
      await _updateNext();
    }
    notifyListeners();
  }

  Future<void> _insertPrio(int index, Iterable<Song> songs) async {
    if (songs.isEmpty) return;
    Log.trace(
      "insert ${songs.length} songs into priority queue at position $index/$_prioLength",
    );
    if (index < 0 || index > _prioLength) {
      throw IndexError.withLength(
        index,
        _regularLength,
        message: "index out of bounds",
      );
    }
    Song? newCurrent;
    if (index == 0 && current.value == null) {
      newCurrent = songs.first;
      songs = songs.skip(1);
    }
    await _db.transaction(() async {
      if (index < _prioLength) {
        await _db.managers.priorityQueueSongTable
            .filter((f) => f.index.isBiggerOrEqualTo(index))
            .update(
              (o) => PriorityQueueSongTableCompanion.custom(
                index:
                    _db.priorityQueueSongTable.index + Constant(songs.length),
              ),
            );
      }
      await _db.managers.priorityQueueSongTable.bulkCreate(
        (o) => songs.mapIndexed((i, s) => o(index: index + i, songId: s.id)),
      );
    });
    _prioLength += songs.length;
    if (index == 0) {
      if (newCurrent != null) {
        await _currentChanged(newCurrent);
        await _updateCurrentIndex(-1);
      } else {
        await _updateNext(next: songs.first);
      }
    }
    notifyListeners();
  }

  Future<void> _updateCurrentIndex(int currentIndex) async {
    if (looping.value && _regularLength > 0) {
      currentIndex %= _regularLength;
    } else if (currentIndex < 0) {
      currentIndex = -1;
    }
    _currentIndex = currentIndex;
    await _db.managers.queueTable
        .filter((f) => f.id(_currentQueueId))
        .update((o) => o(currentIndex: Value(currentIndex)));
  }

  Future<void> _currentChanged(
    Song? current, {
    bool fromAdvance = false,
  }) async {
    _current.add(current);
    _currentAndNext.add((
      current: current,
      next: await _getNextSong(),
      currentChanged: true,
      fromAdvance: fromAdvance,
    ));
    if (current != null) {
      await _keyValue.store(_currentSongIdKey, current.id);
    } else {
      await _keyValue.remove(_currentSongIdKey);
    }
  }

  Future<void> _updateNext({Song? next}) async {
    next ??= await _getNextSong();
    if (currentAndNext.value.next?.id == next?.id) return;
    _currentAndNext.add((
      current: currentAndNext.value.current,
      next: next,
      currentChanged: false,
      fromAdvance: false,
    ));
  }

  Future<Song?> _getNextSong() async {
    if (_prioLength > 0) {
      final q = _db.select(_db.priorityQueueSongTable).join([
        innerJoin(
          _db.songTable,
          _db.priorityQueueSongTable.songId.equalsExp(_db.songTable.id),
        ),
      ]);
      q.where(_db.priorityQueueSongTable.index.equals(0));
      final dbSong = await q
          .map((row) => row.readTable(_db.songTable))
          .getSingle();
      return _songRepo.songFromDBModel(dbSong);
    }
    if (_regularLength == 0 ||
        (!looping.value && _currentIndex >= _regularLength - 1)) {
      return null;
    }
    final q = _db.select(_db.queueSongTable).join([
      innerJoin(
        _db.songTable,
        _db.queueSongTable.songId.equalsExp(_db.songTable.id),
      ),
    ]);
    q.where(
      _db.queueSongTable.queueId.equals(_currentQueueId) &
          _db.queueSongTable.index.equals(_nextIndex),
    );
    final dbSong = await q
        .map((row) => row.readTable(_db.songTable))
        .getSingle();
    return _songRepo.songFromDBModel(dbSong);
  }

  Future<void> advance() {
    return _advance(true);
  }

  Future<Song?> _extractPrioSong([int index = 0]) async {
    final song =
        await (_db.select(_db.priorityQueueSongTable).join([
              innerJoin(
                _db.songTable,
                _db.priorityQueueSongTable.songId.equalsExp(_db.songTable.id),
              ),
            ])..where(_db.priorityQueueSongTable.index.equals(index)))
            .map((row) => row.readTable(_db.songTable))
            .getSingleOrNull();
    if (song != null) {
      int deleted = 0;
      await _db.transaction(() async {
        deleted = await _db.managers.priorityQueueSongTable
            .filter((f) => f.index.isSmallerOrEqualTo(index))
            .delete();
        await _db.managers.priorityQueueSongTable.update(
          (o) => PriorityQueueSongTableCompanion.custom(
            index: _db.priorityQueueSongTable.index - Variable(deleted),
          ),
        );
      });
      _prioLength -= deleted;
      return _songRepo.songFromDBModel(song);
    }
    return null;
  }

  Future<Song?> _getSongAt(int index, {String? queueId}) async {
    queueId ??= _currentQueueId;
    final song =
        await (_db.select(_db.queueSongTable).join([
              innerJoin(
                _db.songTable,
                _db.queueSongTable.songId.equalsExp(_db.songTable.id),
              ),
            ])..where(
              _db.queueSongTable.queueId.equals(queueId) &
                  _db.queueSongTable.index.equals(index),
            ))
            .map((row) => row.readTable(_db.songTable))
            .getSingleOrNull();
    if (song == null) return null;
    return _songRepo.songFromDBModel(song);
  }

  Future<void> _advance(bool fromAdvance) async {
    if (!canAdvance && !fromAdvance) {
      throw StateError("End of queue already reached");
    }
    if (_prioLength > 0) {
      final song = await _extractPrioSong();
      await _currentChanged(song, fromAdvance: fromAdvance);
    } else if (_nextIndex < _regularLength) {
      await _updateCurrentIndex(_nextIndex);
      final song = await _getSongAt(_currentIndex);
      await _currentChanged(song, fromAdvance: fromAdvance);
    } else if (current.value != null) {
      await _currentChanged(null, fromAdvance: fromAdvance);
    }
    notifyListeners();
  }

  bool get canAdvance => _prioLength > 0 || _nextIndex < _regularLength;

  bool get canGoBack =>
      _regularLength > 0 && (looping.value || _currentIndex > 0);

  Future<void> clear({
    bool queue = true,
    int fromIndex = 0,
    bool priorityQueue = true,
  }) async {
    if (queue && fromIndex == 0 && _currentQueueId != _defaultQueueId) {
      await deleteQueue(_currentQueueId);
      await clear(
        queue: queue,
        fromIndex: fromIndex,
        priorityQueue: priorityQueue,
      );
      return;
    }

    int deletedRegular = 0;
    await _db.transaction(() async {
      if (queue) {
        deletedRegular = await _db.managers.queueSongTable
            .filter(
              (f) =>
                  f.queueId.id(_currentQueueId) &
                  f.index.isBiggerOrEqualTo(fromIndex),
            )
            .delete();
      }
      if (priorityQueue) {
        await _db.managers.priorityQueueSongTable.delete();
      }
    });
    _regularLength -= deletedRegular;
    if (priorityQueue) {
      _prioLength = 0;
    }
    if (queue && (fromIndex == 0 || fromIndex <= _currentIndex)) {
      if (_prioLength > 0) {
        final song = await _extractPrioSong();
        await _updateCurrentIndex(fromIndex - 1);
        await _currentChanged(song!);
      } else if (_nextIndex < fromIndex) {
        await _updateCurrentIndex(_currentIndex + 1);
        final song = await _getSongAt(_currentIndex);
        await _currentChanged(song);
      } else if (_current.value != null) {
        await _updateCurrentIndex(fromIndex - 1);
        await _currentChanged(await _getSongAt(_currentIndex));
      } else {
        await _updateNext();
      }
    } else {
      await _updateNext();
    }

    notifyListeners();
  }

  int get currentIndex => _currentIndex;

  Future<Iterable<Song>> getPrioritySongs({int? limit, int offset = 0}) async {
    final q = _db.select(_db.priorityQueueSongTable).join([
      innerJoin(
        _db.songTable,
        _db.songTable.id.equalsExp(_db.priorityQueueSongTable.songId),
      ),
    ]);
    q.orderBy([OrderingTerm.asc(_db.priorityQueueSongTable.index)]);
    q.limit(limit ?? _prioLength, offset: offset);
    return await q
        .map((row) => _songRepo.songFromDBModel(row.readTable(_db.songTable)))
        .get();
  }

  Future<Iterable<Song>> getRegularSongs({int? limit, int offset = 0}) async {
    final q = _db.select(_db.queueSongTable).join([
      innerJoin(
        _db.songTable,
        _db.songTable.id.equalsExp(_db.queueSongTable.songId),
      ),
    ]);
    q.where(_db.queueSongTable.queueId.equals(_currentQueueId));
    q.orderBy([OrderingTerm.asc(_db.queueSongTable.index)]);
    q.limit(limit ?? _regularLength, offset: offset);
    return await q
        .map((row) => _songRepo.songFromDBModel(row.readTable(_db.songTable)))
        .get();
  }

  Future<void> goTo(int index) async {
    if (index < 0 || index >= _regularLength) {
      throw IndexError.withLength(
        index,
        _regularLength,
        message: "index out of bounds",
      );
    }
    if (index == _currentIndex) return;
    await _updateCurrentIndex(index);
    await _currentChanged(await _getSongAt(_currentIndex));
    notifyListeners();
  }

  Future<void> goToPriority(int index) async {
    if (index < 0 || index >= _prioLength) {
      throw IndexError.withLength(
        index,
        _prioLength,
        message: "index out of bounds",
      );
    }
    final song = await _extractPrioSong(index);
    await _currentChanged(song);
    notifyListeners();
  }

  int get length => _regularLength;

  int get priorityLength => _prioLength;

  int get _nextIndex {
    if (!looping.value || _regularLength == 0) return _currentIndex + 1;
    return (_currentIndex + 1) % _regularLength;
  }

  Future<void> remove(int index) async {
    if (index < 0 || index >= _regularLength) {
      throw IndexError.withLength(
        index,
        _regularLength,
        message: "index out of bounds",
      );
    }
    await _db.transaction(() async {
      await _db.managers.queueSongTable
          .filter((f) => f.queueId.id(_currentQueueId) & f.index(index))
          .delete();
      await _db.managers.queueSongTable
          .filter(
            (f) => f.queueId.id(_currentQueueId) & f.index.isBiggerThan(index),
          )
          .update(
            (o) => QueueSongTableCompanion.custom(
              index: _db.queueSongTable.index - const Constant(1),
            ),
          );
    });
    _regularLength--;
    if (_currentIndex == index) {
      if (_prioLength > 0) {
        await _updateCurrentIndex(_currentIndex - 1);
      }
      if (canAdvance) {
        await _advance(false);
      } else {
        await _currentChanged(null, fromAdvance: false);
      }
    } else if (index == _nextIndex) {
      await _updateNext();
    }
    notifyListeners();
  }

  Future<void> removeFromPriorityQueue(int index) async {
    if (index < 0 || index >= _prioLength) {
      throw IndexError.withLength(
        index,
        _prioLength,
        message: "index out of bounds",
      );
    }
    await _db.transaction(() async {
      await _db.managers.priorityQueueSongTable
          .filter((f) => f.index(index))
          .delete();
      await _db.managers.priorityQueueSongTable
          .filter((f) => f.index.isBiggerThan(index))
          .update(
            (o) => PriorityQueueSongTableCompanion.custom(
              index: _db.priorityQueueSongTable.index - const Constant(1),
            ),
          );
    });
    _prioLength--;
    if (index == 0) {
      await _updateNext();
    }
    notifyListeners();
  }

  Future<void> replace(Iterable<Song> songs, [int startIndex = 0]) async {
    if (songs.isEmpty) {
      await clear(priorityQueue: false);
      return;
    }
    if (startIndex < 0 || startIndex >= songs.length) {
      throw IndexError.withLength(
        startIndex,
        songs.length,
        message: "startIndex out of bounds",
      );
    }

    if (_currentQueueId != _defaultQueueId) {
      await switchQueue(_defaultQueueId, notify: false, updateCurrent: false);
    }

    final queueId = _currentQueueId;
    await _db.transaction(() async {
      await _db.managers.queueSongTable
          .filter((f) => f.queueId.id(queueId))
          .delete();
      await _db.managers.queueSongTable.bulkCreate(
        (o) => songs.mapIndexed(
          (i, s) => o(index: i, songId: s.id, queueId: queueId),
        ),
      );
    });
    _regularLength = songs.length;
    await _updateCurrentIndex(startIndex);
    await _currentChanged(await _getSongAt(_currentIndex));
    notifyListeners();
  }

  Future<void> setLoop(bool loop) async {
    if (loop == looping.value) return;
    await _db.managers.queueTable
        .filter((f) => f.id(_currentQueueId))
        .update((o) => o(loop: Value(loop)));
    _looping.add(loop);
    if (_nextIndex < _currentIndex) {
      await _updateNext();
    }
    notifyListeners();
  }

  Future<void> shuffleFollowing() async {
    await _db.customUpdate(
      "WITH shuffled_indices AS (SELECT \"index\", ROW_NUMBER() OVER (ORDER BY RANDOM()) + ? AS new_index FROM queue_song WHERE queue_song.\"index\" > ?)"
      "UPDATE queue_song SET \"index\" = (SELECT new_index FROM shuffled_indices WHERE shuffled_indices.\"index\" = queue_song.\"index\") WHERE queue_song.\"index\" > ?",
      updateKind: UpdateKind.update,
      updates: {_db.queueSongTable},
      variables: [
        Variable(_currentIndex),
        Variable(_currentIndex),
        Variable(_currentIndex),
      ],
    );
    notifyListeners();
  }

  Future<void> shufflePriority() async {
    await _db.customUpdate(
      "WITH shuffled_indices AS (SELECT \"index\", ROW_NUMBER() OVER (ORDER BY RANDOM()) AS new_index FROM priority_queue)"
      "UPDATE priority_queue SET \"index\" = (SELECT new_index FROM shuffled_indices WHERE shuffled_indices.\"index\" = priority_queue.\"index\")",
      updateKind: UpdateKind.update,
      updates: {_db.priorityQueueSongTable},
    );
    notifyListeners();
  }

  Future<void> skipNext() {
    return _advance(false);
  }

  Future<void> skipPrev() async {
    if (!canGoBack) throw StateError("Cannot go back in empty queue");
    await _updateCurrentIndex(_currentIndex - 1);
    await _currentChanged(await _getSongAt(_currentIndex));
    notifyListeners();
  }
}
