import 'dart:collection';

import 'package:crossonic/data/repositories/audio/queue/media_queue.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class LocalQueue extends ChangeNotifier implements MediaQueue {
  final BehaviorSubject<({Song? song, bool fromAdvance})> _current =
      BehaviorSubject.seeded((song: null, fromAdvance: false));
  @override
  ValueStream<({Song? song, bool fromAdvance})> get current => _current.stream;

  final BehaviorSubject<Song?> _next = BehaviorSubject.seeded(null);
  @override
  ValueStream<Song?> get next => _next.stream;

  final _priorityQueue = Queue<Song>();
  final _queue = <Song>[];

  int _currentIndex = -1;

  final BehaviorSubject<bool> _looping = BehaviorSubject.seeded(false);
  @override
  ValueStream<bool> get looping => _looping.stream;

  @override
  void setLoop(bool loop) {
    if (_looping.value == loop) return;
    _looping.add(loop);
    if (_priorityQueue.isEmpty) {
      _next.add(_queue.elementAtOrNull(_nextIndex));
    }
    notifyListeners();
  }

  @override
  void add(Song song, bool priority) {
    addAll([song], priority);
  }

  @override
  void addAll(Iterable<Song> songs, bool priority) {
    if (priority) {
      _insertPrio(_priorityQueue.length, songs);
    } else {
      _insert(_queue.length, songs);
    }
  }

  @override
  void insert(int index, Song song, bool priority) {
    insertAll(index, [song], priority);
  }

  @override
  void insertAll(int index, Iterable<Song> songs, bool priority) {
    if (priority) {
      _insertPrio(index, songs);
    } else {
      _insert(index, songs);
    }
  }

  @override
  void replace(Iterable<Song> songs, [int startIndex = 0]) {
    if (songs.isEmpty) {
      clear(priorityQueue: false);
      return;
    }
    if (startIndex < 0 || startIndex >= songs.length) {
      throw IndexError.withLength(startIndex, songs.length,
          message: "startIndex out of bounds");
    }
    _queue.clear();
    _queue.addAll(songs);
    _currentIndex = startIndex;
    _current.add((song: _queue[_currentIndex], fromAdvance: false));
    if (_priorityQueue.isEmpty) {
      _next.add(_queue.elementAtOrNull(_nextIndex));
    }
    notifyListeners();
  }

  @override
  void clear(
      {bool queue = true, int fromIndex = 0, bool priorityQueue = true}) {
    if (priorityQueue) {
      _priorityQueue.clear();
    }
    if (queue) {
      if (fromIndex < _queue.length) {
        _queue.removeRange(fromIndex, _queue.length);
      }
      if (fromIndex <= _currentIndex) {
        if (_priorityQueue.isNotEmpty) {
          _current
              .add((song: _priorityQueue.removeFirst(), fromAdvance: false));
        } else if (_nextIndex < fromIndex) {
          _incrementCurrentIndex();
          _current.add((song: _queue[_currentIndex], fromAdvance: false));
        } else if (_current.value.song != null) {
          _current.add((song: null, fromAdvance: false));
        }
      }
    }
    _next.add(_priorityQueue.isNotEmpty
        ? _priorityQueue.first
        : _queue.elementAtOrNull(_nextIndex));
    notifyListeners();
  }

  @override
  void goTo(int index) {
    if (index < 0 || index >= _queue.length) {
      throw IndexError.withLength(index, _queue.length,
          message: "index out of bounds");
    }
    if (index == _currentIndex) return;
    _currentIndex = index;
    _current.add((song: _queue[_currentIndex], fromAdvance: false));
    _next.add(_priorityQueue.isNotEmpty
        ? _priorityQueue.first
        : _queue.elementAtOrNull(_nextIndex));
    notifyListeners();
  }

  @override
  void goToPriority(int index) {
    if (index < 0 || index >= _priorityQueue.length) {
      throw IndexError.withLength(index, _priorityQueue.length,
          message: "index out of bounds");
    }
    while (index > 0) {
      _priorityQueue.removeFirst();
    }
    _current.add((song: _priorityQueue.removeFirst(), fromAdvance: false));
    _next.add(_priorityQueue.isNotEmpty
        ? _priorityQueue.first
        : _queue.elementAtOrNull(_nextIndex));
    notifyListeners();
  }

  @override
  void remove(int index) {
    if (index < 0 || index >= _queue.length) {
      throw IndexError.withLength(index, _queue.length,
          message: "index out of bounds");
    }
    _queue.removeAt(index);
    if (_currentIndex == index) {
      _incrementCurrentIndex();
      _current.add((song: _next.value, fromAdvance: false));
      _next.add(_priorityQueue.isNotEmpty
          ? _priorityQueue.first
          : _queue.elementAtOrNull(_nextIndex));
    } else if (_nextIndex == index && _priorityQueue.isEmpty) {
      _next.add(_queue.elementAtOrNull(_nextIndex));
    }
    notifyListeners();
  }

  @override
  void removeFromPriorityQueue(int index) {
    if (index < 0 || index >= _priorityQueue.length) {
      throw IndexError.withLength(index, _priorityQueue.length,
          message: "index out of bounds");
    }
    if (index == 0) {
      _priorityQueue.removeFirst();
    } else if (index == _priorityQueue.length - 1) {
      _priorityQueue.removeLast();
    } else {
      final list = List.of(_priorityQueue);
      _priorityQueue.clear();
      _priorityQueue.addAll(list
          .getRange(0, index)
          .followedBy(list.getRange(index + 1, list.length)));
    }
    notifyListeners();
  }

  void _insert(int index, Iterable<Song> songs) {
    if (songs.isEmpty) return;
    if (index < 0 || index > _queue.length) {
      throw IndexError.withLength(index, _queue.length,
          message: "index out of bounds");
    }
    _queue.insertAll(index, songs);
    if (current.value.song == null) {
      _current.add((song: _queue.first, fromAdvance: false));
      _currentIndex = 0;
    }
    if (_priorityQueue.isEmpty) {
      _next.add(_queue.elementAtOrNull(_nextIndex));
    }
    notifyListeners();
  }

  void _insertPrio(int index, Iterable<Song> songs) {
    if (songs.isEmpty) return;

    if (index == _priorityQueue.length) {
      _priorityQueue.addAll(songs);
    } else {
      final list = _priorityQueue.toList();
      list.insertAll(index, songs);
      _priorityQueue.clear();
      _priorityQueue.addAll(list);
    }

    if (index == 0) {
      if (current.value.song == null) {
        _current.add((song: _priorityQueue.removeFirst(), fromAdvance: false));
        _currentIndex = 0;
      }
      _next.add(_priorityQueue.firstOrNull);
    }

    notifyListeners();
  }

  @override
  void shuffleFollowing() {
    if (_currentIndex >= _queue.length - 1) return;
    final following = _queue.sublist(_currentIndex + 1);
    following.shuffle();
    _queue.removeRange(_currentIndex + 1, _queue.length);
    _queue.addAll(following);
    if (_priorityQueue.isEmpty) {
      _next.add(_queue.elementAtOrNull(_nextIndex));
    }
    notifyListeners();
  }

  @override
  void shufflePriority() {
    if (_priorityQueue.isEmpty) return;
    final newQueue = _priorityQueue.toList()..shuffle();
    _priorityQueue.clear();
    _priorityQueue.addAll(newQueue);
    _next.add(_priorityQueue.first);
    notifyListeners();
  }

  @override
  void advance() {
    _advance(true);
  }

  @override
  void skipNext() {
    _advance(false);
  }

  void _advance(bool fromAdvance) {
    if (!canAdvance && !fromAdvance) {
      throw StateError("End of queue already reached");
    }
    if (_priorityQueue.isNotEmpty) {
      _current
          .add((song: _priorityQueue.removeFirst(), fromAdvance: fromAdvance));
    } else if (_nextIndex < _queue.length) {
      _incrementCurrentIndex();
      _current.add((song: _queue[_currentIndex], fromAdvance: fromAdvance));
    } else {
      if (_current.value.song != null) {
        _current.add((song: null, fromAdvance: fromAdvance));
      }
    }
    _next.add(_priorityQueue.isNotEmpty
        ? _priorityQueue.first
        : _queue.elementAtOrNull(_nextIndex));
    notifyListeners();
  }

  @override
  void skipPrev() {
    if (!canGoBack) throw StateError("Cannot go back in empty queue");
    _decrementCurrentIndex();
    _current.add((song: _queue[_currentIndex], fromAdvance: false));
    _next.add(_priorityQueue.isNotEmpty
        ? _priorityQueue.first
        : _queue.elementAtOrNull(_nextIndex));
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
    if (!looping.value) return _currentIndex + 1;
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
  Iterable<Song> get regular => _queue;

  @override
  Iterable<Song> get priority => _priorityQueue;

  @override
  int get currentIndex => _currentIndex;
}
