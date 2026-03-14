import 'dart:collection';
import 'dart:math';

import 'package:crossonic/data/repositories/audio/queue/media_queue.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

class LocalQueue extends ChangeNotifier implements MediaQueue {
  final BehaviorSubject<Song?> _current = BehaviorSubject.seeded(null);
  @override
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
  @override
  ValueStream<
    ({Song? current, Song? next, bool currentChanged, bool fromAdvance})
  >
  get currentAndNext => _currentAndNext.stream;

  final Queue<Song> _priorityQueue;
  final List<Song> _queue;

  int _currentIndex;

  LocalQueue()
    : _priorityQueue = Queue(),
      _queue = [],
      _currentIndex = -1,
      _looping = BehaviorSubject.seeded(false);

  LocalQueue.withInitialData({
    required Queue<Song> priorityQueue,
    required List<Song> regularQueue,
    required bool looping,
    required int currentIndex,
    required Song currentSong,
  }) : _priorityQueue = priorityQueue,
       _queue = regularQueue,
       _currentIndex = currentIndex,
       _looping = BehaviorSubject.seeded(looping) {
    _current.add(currentSong);
    _currentAndNext.add((
      current: currentSong,
      next: _priorityQueue.isNotEmpty
          ? _priorityQueue.first
          : _queue.elementAtOrNull(_nextIndex),
      currentChanged: true,
      fromAdvance: false,
    ));
  }

  final BehaviorSubject<bool> _looping;
  @override
  ValueStream<bool> get looping => _looping.stream;

  @override
  Future<void> setLoop(bool loop) async {
    if (_looping.value == loop) return;
    Log.trace("loop: $loop");
    _looping.add(loop);
    _updateNext();
    notifyListeners();
  }

  @override
  Future<void> add(Song song, bool priority) async {
    addAll([song], priority);
  }

  @override
  Future<void> addAll(Iterable<Song> songs, bool priority) async {
    if (priority) {
      _insertPrio(_priorityQueue.length, songs);
    } else {
      _insert(_queue.length, songs);
    }
  }

  @override
  Future<void> insert(int index, Song song, bool priority) async {
    insertAll(index, [song], priority);
  }

  @override
  Future<void> insertAll(int index, Iterable<Song> songs, bool priority) async {
    if (priority) {
      _insertPrio(index, songs);
    } else {
      _insert(index, songs);
    }
  }

  @override
  Future<void> replace(Iterable<Song> songs, [int startIndex = 0]) async {
    if (songs.isEmpty) {
      clear(priorityQueue: false);
      return;
    }
    if (startIndex < 0 || startIndex >= songs.length) {
      throw IndexError.withLength(
        startIndex,
        songs.length,
        message: "startIndex out of bounds",
      );
    }
    _queue.clear();
    _queue.addAll(songs);
    _currentIndex = startIndex;
    _currentChanged(_queue[_currentIndex]);
    notifyListeners();
  }

  @override
  Future<void> clear({
    bool queue = true,
    int fromIndex = 0,
    bool priorityQueue = true,
  }) async {
    if (priorityQueue) {
      _priorityQueue.clear();
    }
    if (queue) {
      if (fromIndex < _queue.length) {
        _queue.removeRange(fromIndex, _queue.length);
      }
      if (fromIndex <= _currentIndex) {
        if (_priorityQueue.isNotEmpty) {
          _currentChanged(_priorityQueue.removeFirst());
        } else if (_nextIndex < fromIndex) {
          _incrementCurrentIndex();
          _currentChanged(_queue[_currentIndex]);
        } else if (_current.value != null) {
          _currentChanged(null);
        }
      }
    }
    _updateNext();
    notifyListeners();
  }

  @override
  Future<void> goTo(int index) async {
    if (index < 0 || index >= _queue.length) {
      throw IndexError.withLength(
        index,
        _queue.length,
        message: "index out of bounds",
      );
    }
    if (index == _currentIndex) return;
    _currentIndex = index;
    _currentChanged(_queue[_currentIndex]);
    notifyListeners();
  }

  @override
  Future<void> goToPriority(int index) async {
    if (index < 0 || index >= _priorityQueue.length) {
      throw IndexError.withLength(
        index,
        _priorityQueue.length,
        message: "index out of bounds",
      );
    }
    for (; index > 0; index--) {
      _priorityQueue.removeFirst();
    }
    _currentChanged(_priorityQueue.removeFirst());
    notifyListeners();
  }

  @override
  Future<void> remove(int index) async {
    if (index < 0 || index >= _queue.length) {
      throw IndexError.withLength(
        index,
        _queue.length,
        message: "index out of bounds",
      );
    }
    _queue.removeAt(index);
    if (_currentIndex == index) {
      _incrementCurrentIndex();
      _currentChanged(_currentAndNext.value.next);
    } else {
      _updateNext();
    }
    notifyListeners();
  }

  @override
  Future<void> removeFromPriorityQueue(int index) async {
    if (index < 0 || index >= _priorityQueue.length) {
      throw IndexError.withLength(
        index,
        _priorityQueue.length,
        message: "index out of bounds",
      );
    }
    if (index == 0) {
      _priorityQueue.removeFirst();
    } else if (index == _priorityQueue.length - 1) {
      _priorityQueue.removeLast();
    } else {
      final list = List.of(_priorityQueue);
      _priorityQueue.clear();
      _priorityQueue.addAll(
        list
            .getRange(0, index)
            .followedBy(list.getRange(index + 1, list.length)),
      );
    }
    _updateNext();
    notifyListeners();
  }

  Future<void> _insert(int index, Iterable<Song> songs) async {
    if (songs.isEmpty) return;
    Log.trace(
      "insert ${songs.length} songs into regular queue at position $index/${_queue.length}",
    );
    if (index < 0 || index > _queue.length) {
      throw IndexError.withLength(
        index,
        _queue.length,
        message: "index out of bounds",
      );
    }
    _queue.insertAll(index, songs);
    if (current.value == null) {
      _currentChanged(_queue.first);
      _currentIndex = 0;
    } else {
      _updateNext();
    }
    notifyListeners();
  }

  void _insertPrio(int index, Iterable<Song> songs) {
    if (songs.isEmpty) return;
    Log.trace(
      "insert ${songs.length} songs into priority queue at position $index/${_priorityQueue.length}",
    );
    if (index == _priorityQueue.length) {
      _priorityQueue.addAll(songs);
    } else {
      final list = _priorityQueue.toList();
      list.insertAll(index, songs);
      _priorityQueue.clear();
      _priorityQueue.addAll(list);
    }

    if (index == 0) {
      if (current.value == null) {
        _currentChanged(_priorityQueue.removeFirst());
        _currentIndex = 0;
      } else {
        _updateNext();
      }
    }

    notifyListeners();
  }

  @override
  Future<void> shuffleFollowing() async {
    Log.trace("shuffle following songs in queue");
    if (_currentIndex >= _queue.length - 1) {
      Log.warn("no following songs to shuffle");
      return;
    }
    final following = _queue.sublist(_currentIndex + 1);
    following.shuffle();
    _queue.removeRange(_currentIndex + 1, _queue.length);
    _queue.addAll(following);
    _updateNext();
    notifyListeners();
  }

  @override
  Future<void> shufflePriority() async {
    if (_priorityQueue.isEmpty) return;
    Log.trace("shuffle songs in priority queue");
    final newQueue = _priorityQueue.toList()..shuffle();
    _priorityQueue.clear();
    _priorityQueue.addAll(newQueue);
    _updateNext();
    notifyListeners();
  }

  @override
  Future<void> advance() async {
    _advance(true);
  }

  @override
  Future<void> skipNext() async {
    _advance(false);
  }

  void _advance(bool fromAdvance) async {
    if (!canAdvance && !fromAdvance) {
      throw StateError("End of queue already reached");
    }
    if (_priorityQueue.isNotEmpty) {
      _currentChanged(_priorityQueue.removeFirst(), fromAdvance: fromAdvance);
    } else if (_nextIndex < _queue.length) {
      _incrementCurrentIndex();
      _currentChanged(_queue[_currentIndex], fromAdvance: fromAdvance);
    } else if (_current.value != null) {
      _currentChanged(null, fromAdvance: fromAdvance);
    }
    notifyListeners();
  }

  @override
  Future<void> skipPrev() async {
    if (!canGoBack) throw StateError("Cannot go back in empty queue");
    _decrementCurrentIndex();
    _currentChanged(_queue[_currentIndex]);
    notifyListeners();
  }

  void _incrementCurrentIndex() {
    _currentIndex++;
    _normalizeCurrentIndex();
  }

  void _decrementCurrentIndex() {
    _currentIndex--;
    _normalizeCurrentIndex();
  }

  void _normalizeCurrentIndex() {
    if (looping.value) {
      _currentIndex %= _queue.length;
    } else if (_currentIndex < 0) {
      _currentIndex = -1;
    }
  }

  int get _nextIndex {
    if (!looping.value || _queue.isEmpty) return _currentIndex + 1;
    return (_currentIndex + 1) % _queue.length;
  }

  @override
  bool get canGoBack =>
      _queue.isNotEmpty && (looping.value || _currentIndex > 0);

  @override
  bool get canAdvance =>
      _priorityQueue.isNotEmpty || _nextIndex < _queue.length;

  @override
  int get length => _queue.length;

  @override
  int get priorityLength => _priorityQueue.length;

  @override
  int get currentIndex => _currentIndex;

  @override
  Future<Iterable<Song>> getRegularSongs({int? limit, int offset = 0}) async {
    final start = min(offset, _queue.length);
    final end = min((limit ?? _queue.length) + start, _queue.length);
    return _queue.getRange(start, end);
  }

  @override
  Future<Iterable<Song>> getPrioritySongs({int? limit, int offset = 0}) async {
    return _priorityQueue
        .skip(min(offset, _queue.length))
        .take(limit ?? _queue.length);
  }

  void _currentChanged(Song? current, {bool fromAdvance = false}) {
    _current.add(current);
    _currentAndNext.add((
      current: current,
      next: current == null
          ? null
          : _priorityQueue.isNotEmpty
          ? _priorityQueue.first
          : _queue.elementAtOrNull(_nextIndex),
      currentChanged: true,
      fromAdvance: fromAdvance,
    ));
  }

  void _updateNext() {
    final next = _current.value != null
        ? (_priorityQueue.isNotEmpty
              ? _priorityQueue.first
              : _queue.elementAtOrNull(_nextIndex))
        : null;
    if (_currentAndNext.value.next?.id == next?.id) return;
    _currentAndNext.add((
      current: _currentAndNext.value.current,
      next: next,
      currentChanged: false,
      fromAdvance: false,
    ));
  }
}
