import 'dart:collection';
import 'package:crossonic/exceptions.dart';
import 'package:crossonic/repositories/api/api.dart';
import 'package:rxdart/rxdart.dart';

class CurrentMedia {
  final Media item;
  final Media? next;
  final bool currentChanged;
  final bool fromNext;
  final bool inPriorityQueue;
  final int index;
  const CurrentMedia(
    this.item,
    this.next, {
    required this.index,
    this.currentChanged = true,
    this.fromNext = false,
    required this.inPriorityQueue,
  });
}

class MediaQueue {
  final _priorityQueue = Queue<Media>();
  final _queue = <Media>[];
  final BehaviorSubject<CurrentMedia?> current = BehaviorSubject.seeded(null);
  final BehaviorSubject<bool> loop = BehaviorSubject.seeded(false);

  List<Media> get queue => _queue;
  Queue<Media> get priorityQueue => _priorityQueue;

  var _nextIndex = 0;

  void setLoop(bool value) {
    loop.add(value);
    if (current.value == null) return;
    if (value) {
      if (_nextIndex >= length) {
        _nextIndex %= length;
      }
      if (current.value!.next == null) {
        current.add(CurrentMedia(
          current.value!.item,
          _queue.elementAtOrNull(_nextIndex),
          index: current.value!.index,
          inPriorityQueue: current.value!.inPriorityQueue,
          currentChanged: false,
        ));
      }
    } else if (_nextIndex <= current.value!.index) {
      _nextIndex = current.value!.index + 1;
      if (_priorityQueue.isEmpty) {
        current.add(CurrentMedia(
          current.value!.item,
          _queue.elementAtOrNull(_nextIndex),
          index: current.value!.index,
          inPriorityQueue: current.value!.inPriorityQueue,
          currentChanged: false,
        ));
      }
    }
  }

  void replaceQueue(List<Media> songs, [int startIndex = 0]) {
    _queue.clear();
    _queue.addAll(songs);
    _nextIndex = startIndex + 1;
    if (loop.value) {
      _nextIndex %= length;
    }
    current.add(CurrentMedia(
      _queue[startIndex],
      _priorityQueue.isNotEmpty
          ? _priorityQueue.first
          : _queue.elementAtOrNull(_nextIndex),
      index: startIndex,
      inPriorityQueue: false,
    ));
  }

  void add(Media song) {
    addAll([song]);
  }

  void addAll(Iterable<Media> songs) {
    _queue.addAll(songs);
    if (current.value == null) {
      _nextIndex = 1;
      if (loop.value) {
        _nextIndex %= length;
      }
      current.add(CurrentMedia(
        _queue[0],
        _priorityQueue.isNotEmpty
            ? _priorityQueue.first
            : _queue.elementAtOrNull(_nextIndex),
        index: 0,
        inPriorityQueue: false,
      ));
    } else {
      if (_nextIndex != current.value!.index + 1) {
        _nextIndex = current.value!.index + 1;
        if (loop.value) {
          _nextIndex %= length;
        }
      }
      current.add(CurrentMedia(
        current.value!.item,
        _priorityQueue.isNotEmpty
            ? _priorityQueue.first
            : _queue.elementAtOrNull(_nextIndex),
        index: current.value!.index,
        currentChanged: false,
        inPriorityQueue: current.value!.inPriorityQueue,
      ));
    }
  }

  void insert(int index, Media song) {
    if (index == _queue.length) {
      add(song);
      return;
    }
    _queue.insert(index, song);
    if (index == _nextIndex && _priorityQueue.isEmpty) {
      current.add(CurrentMedia(
        current.value!.item,
        _queue.elementAtOrNull(_nextIndex),
        index: current.value!.index,
        currentChanged: false,
        inPriorityQueue: current.value!.inPriorityQueue,
      ));
    }
    if (index < _nextIndex) _nextIndex++;
  }

  void remove(int index) {
    _queue.removeAt(index);
    if (index == _nextIndex && _priorityQueue.isEmpty) {
      current.add(CurrentMedia(
        current.value!.item,
        _queue.elementAtOrNull(_nextIndex),
        index: current.value!.index,
        currentChanged: false,
        inPriorityQueue: current.value!.inPriorityQueue,
      ));
    }
    if (index < _nextIndex) {
      _nextIndex--;
      if (loop.value) {
        _nextIndex %= length;
      }
    }
  }

  void removeAllFollowing() {
    if (_nextIndex >= _queue.length) return;
    _queue.removeRange(_nextIndex, _queue.length);
    if (_priorityQueue.isEmpty) {
      current.add(CurrentMedia(
        current.value!.item,
        _queue.elementAtOrNull(_nextIndex),
        index: current.value!.index,
        currentChanged: false,
        inPriorityQueue: current.value!.inPriorityQueue,
      ));
    }
  }

  void clear() {
    clearPriorityQueue();
    _queue.clear();
    _nextIndex = 0;
    if (current.value != null) {
      current.add(null);
    }
  }

  void addToPriorityQueue(Media song) {
    addAllToPriorityQueue([song]);
  }

  void addAllToPriorityQueue(Iterable<Media> songs) {
    _priorityQueue.addAll(songs);
    if (current.value == null) {
      final next = _priorityQueue.removeFirst();
      current.add(CurrentMedia(
        next,
        _priorityQueue.isNotEmpty
            ? _priorityQueue.first
            : _queue.elementAtOrNull(_nextIndex),
        inPriorityQueue: true,
        index: -1,
      ));
      return;
    }
    if (_priorityQueue.length == songs.length) {
      current.add(CurrentMedia(
        current.value!.item,
        _priorityQueue.first,
        currentChanged: false,
        inPriorityQueue: current.value!.inPriorityQueue,
        index: current.value!.index,
      ));
    }
  }

  void removeFromPriorityQueue(int index) {
    if (index == 0) {
      _priorityQueue.removeFirst();
      current.add(CurrentMedia(
        current.value!.item,
        _priorityQueue.isNotEmpty
            ? _priorityQueue.first
            : _queue.elementAtOrNull(_nextIndex),
        currentChanged: false,
        inPriorityQueue: current.value!.inPriorityQueue,
        index: current.value!.index,
      ));
    } else if (index == _priorityQueue.length - 1) {
      _priorityQueue.removeLast();
    } else {
      final list = _priorityQueue.toList();
      list.removeAt(index);
      _priorityQueue.clear();
      _priorityQueue.addAll(list);
    }
  }

  void insertIntoPriorityQueue(int index, Media song) {
    if (index == 0) {
      _priorityQueue.addFirst(song);
      current.add(CurrentMedia(
        current.value!.item,
        _priorityQueue.isNotEmpty
            ? _priorityQueue.first
            : _queue.elementAtOrNull(_nextIndex),
        currentChanged: false,
        inPriorityQueue: current.value!.inPriorityQueue,
        index: current.value!.index,
      ));
    } else if (index == _priorityQueue.length) {
      _priorityQueue.addLast(song);
    } else {
      final list = _priorityQueue.toList();
      list.insert(index, song);
      _priorityQueue.clear();
      _priorityQueue.addAll(list);
    }
  }

  void clearPriorityQueue() {
    if (_priorityQueue.isEmpty) return;
    _priorityQueue.clear();
    current.add(CurrentMedia(
      current.value!.item,
      _queue.elementAtOrNull(_nextIndex),
      currentChanged: false,
      inPriorityQueue: current.value!.inPriorityQueue,
      index: current.value!.index,
    ));
  }

  void gotoPriorityQueue(int index) {
    if (index < 0 || index >= _priorityQueue.length) {
      throw InvalidStateException(
          "Priority queue index out of bounds: no index $index in priority queue of length ${_priorityQueue.length}");
    }
    for (var i = 0; i < index; i++) {
      _priorityQueue.removeFirst();
    }
    final next = _priorityQueue.removeFirst();
    current.add(CurrentMedia(
      next,
      _priorityQueue.isNotEmpty
          ? _priorityQueue.first
          : _queue.elementAtOrNull(_nextIndex),
      inPriorityQueue: true,
      currentChanged: true,
      index: current.value!.index,
    ));
  }

  void shufflePriorityQueue() {
    if (_priorityQueue.isEmpty) return;
    final newQueue = _priorityQueue.toList()..shuffle();
    _priorityQueue.clear();
    _priorityQueue.addAll(newQueue);
    current.add(CurrentMedia(
      current.value!.item,
      _priorityQueue.first,
      currentChanged: false,
      inPriorityQueue: current.value!.inPriorityQueue,
      index: current.value!.index,
    ));
  }

  void shuffleFollowing() {
    if (_nextIndex >= _queue.length) return;
    final following = _queue.sublist(_nextIndex);
    _queue.removeRange(_nextIndex, _queue.length);
    _queue.addAll(following..shuffle());
    if (_priorityQueue.isEmpty) {
      current.add(CurrentMedia(
        current.value!.item,
        _queue.elementAtOrNull(_nextIndex),
        currentChanged: false,
        inPriorityQueue: current.value!.inPriorityQueue,
        index: current.value!.index,
      ));
    }
  }

  void goto(int index) {
    if (index < 0 || index >= _queue.length) {
      throw InvalidStateException(
          "Queue index out of bounds: no index $index in queue of length ${_queue.length}");
    }
    _nextIndex = index + 1;
    if (loop.value) {
      _nextIndex %= length;
    }
    current.add(CurrentMedia(
      _queue[index],
      _priorityQueue.isNotEmpty
          ? _priorityQueue.first
          : _queue.elementAtOrNull(_nextIndex),
      fromNext: false,
      inPriorityQueue: false,
      index: index,
    ));
  }

  bool get canGoBack =>
      (loop.value && length > 0) ||
      (current.value?.inPriorityQueue ?? false
          ? _nextIndex > 0
          : _nextIndex - 1 > 0);
  bool get canAdvance =>
      (loop.value && length > 0) ||
      (_priorityQueue.isNotEmpty || _nextIndex < _queue.length);
  int get length => _queue.length;

  void back() {
    if (!canGoBack) {
      throw const InvalidStateException("Cannot go back in empty queue");
    }
    if (!(current.value?.inPriorityQueue ?? false)) {
      _nextIndex--;
      if (loop.value) {
        _nextIndex %= length;
      }
    }
    final newCurrent = (_nextIndex - 1) % length;
    current.add(CurrentMedia(
      _queue[newCurrent],
      _priorityQueue.isNotEmpty
          ? _priorityQueue.first
          : _queue.elementAtOrNull(_nextIndex),
      inPriorityQueue: false,
      index: newCurrent,
    ));
  }

  bool advance([bool setFromNext = true]) {
    Media next;
    bool inPriorityQueue = false;
    if (_priorityQueue.isNotEmpty) {
      next = _priorityQueue.removeFirst();
      inPriorityQueue = true;
    } else if (_nextIndex < _queue.length) {
      next = _queue[_nextIndex];
      _nextIndex++;
      if (loop.value) {
        _nextIndex %= length;
      }
    } else {
      if (current.value != null) {
        current.add(null);
      }
      return false;
    }
    current.add(CurrentMedia(
      next,
      _priorityQueue.isNotEmpty
          ? _priorityQueue.first
          : _queue.elementAtOrNull(_nextIndex),
      fromNext: setFromNext,
      inPriorityQueue: inPriorityQueue,
      index: (_nextIndex - 1) % length,
    ));
    return true;
  }
}
