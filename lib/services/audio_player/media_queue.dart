import 'dart:collection';
import 'package:crossonic/exceptions.dart';
import 'package:crossonic/repositories/subsonic/subsonic.dart';
import 'package:rxdart/rxdart.dart';

class CurrentMedia {
  final Media item;
  final Media? next;
  final bool currentChanged;
  final bool fromNext;
  final bool inPriorityQueue;
  const CurrentMedia(this.item, this.next,
      {this.currentChanged = true,
      this.fromNext = false,
      this.inPriorityQueue = false});
}

class MediaQueue {
  final _priorityQueue = Queue<Media>();
  final _queue = <Media>[];
  final BehaviorSubject<CurrentMedia?> current = BehaviorSubject()..add(null);

  var _nextIndex = 0;

  void replaceQueue(List<Media> songs, [int startIndex = 0]) {
    _queue.clear();
    _queue.addAll(songs);
    _nextIndex = startIndex + 1;
    current.add(CurrentMedia(
      _queue[startIndex],
      _priorityQueue.isNotEmpty
          ? _priorityQueue.first
          : _queue.elementAtOrNull(_nextIndex),
    ));
  }

  void add(Media song) {
    addAll([song]);
  }

  void addAll(Iterable<Media> songs) {
    _queue.addAll(songs);
    if (current.value == null) {
      _nextIndex = 1;
      current.add(CurrentMedia(
        _queue[0],
        _priorityQueue.isNotEmpty
            ? _priorityQueue.first
            : _queue.elementAtOrNull(_nextIndex),
      ));
    } else if (current.value!.next == null && _nextIndex < songs.length) {
      current.add(CurrentMedia(
        current.value!.item,
        _priorityQueue.isNotEmpty
            ? _priorityQueue.first
            : _queue.elementAtOrNull(_nextIndex),
        currentChanged: false,
      ));
    }
  }

  void remove(int index) {
    _queue.removeAt(index);
    if (index == _nextIndex && _priorityQueue.isEmpty) {
      current.add(CurrentMedia(
        current.value!.item,
        _queue.elementAtOrNull(_nextIndex),
        currentChanged: false,
      ));
    }
    if (index < _nextIndex) _nextIndex--;
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
      ));
      return;
    }
    if (_priorityQueue.length == songs.length) {
      current.add(CurrentMedia(
        current.value!.item,
        _priorityQueue.first,
        currentChanged: false,
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

  void clearPriorityQueue() {
    if (_priorityQueue.isEmpty) return;
    _priorityQueue.clear();
    current.add(CurrentMedia(
      current.value!.item,
      _queue.elementAtOrNull(_nextIndex),
      currentChanged: false,
    ));
  }

  void goto(int index) {
    if (index < 0 || index >= _queue.length) {
      throw InvalidStateException(
          "Queue index out of bounds: no index $index in queue of length ${_queue.length}");
    }
    _nextIndex = index + 1;
    current.add(CurrentMedia(
      _queue[index],
      _priorityQueue.isNotEmpty
          ? _priorityQueue.first
          : _queue.elementAtOrNull(_nextIndex),
      fromNext: true,
    ));
  }

  bool get canGoBack => current.value?.inPriorityQueue ?? false
      ? _nextIndex > 0
      : _nextIndex - 1 > 0;
  bool get canAdvance =>
      _priorityQueue.isNotEmpty || _nextIndex < _queue.length;
  int get length => _queue.length;

  void back() {
    if (!canGoBack) {
      throw const InvalidStateException("Cannot go back in empty queue");
    }
    if (!(current.value?.inPriorityQueue ?? false)) _nextIndex--;
    current.add(CurrentMedia(
      _queue[_nextIndex - 1],
      _priorityQueue.isNotEmpty
          ? _priorityQueue.first
          : _queue.elementAtOrNull(_nextIndex),
    ));
  }

  bool advance() {
    Media next;
    bool inPriorityQueue = false;
    if (_priorityQueue.isNotEmpty) {
      next = _priorityQueue.removeFirst();
      inPriorityQueue = true;
    } else if (_nextIndex < _queue.length) {
      next = _queue[_nextIndex];
      _nextIndex++;
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
      fromNext: true,
      inPriorityQueue: inPriorityQueue,
    ));
    return true;
  }
}
