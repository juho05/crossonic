import 'dart:async';

import 'package:crossonic/data/repositories/audio/queue/media_queue.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

class ChangableQueue extends ChangeNotifier implements MediaQueue {
  MediaQueue _queue;
  StreamSubscription? _currentSubscription;
  StreamSubscription? _currentAndNextSubscription;
  StreamSubscription? _loopingSubscription;

  final BehaviorSubject<Song?> _current;
  @override
  ValueStream<Song?> get current => _current.stream;

  final BehaviorSubject<
    ({Song? current, Song? next, bool currentChanged, bool fromAdvance})
  >
  _currentAndNext;
  @override
  ValueStream<
    ({Song? current, Song? next, bool currentChanged, bool fromAdvance})
  >
  get currentAndNext => _currentAndNext.stream;

  final BehaviorSubject<bool> _looping;
  @override
  ValueStream<bool> get looping => _looping.stream;

  ChangableQueue(MediaQueue queue)
    : _queue = queue,
      _current = BehaviorSubject.seeded(queue.current.value),
      _currentAndNext = BehaviorSubject.seeded(queue.currentAndNext.value),
      _looping = BehaviorSubject.seeded(queue.looping.value) {
    change(queue);
  }

  Future<void> change(MediaQueue queue) async {
    _queue.removeListener(notifyListeners);
    await _currentAndNextSubscription?.cancel();
    await _currentSubscription?.cancel();
    await _loopingSubscription?.cancel();

    _queue = queue;

    _queue.addListener(notifyListeners);

    _currentSubscription = _queue.current.listen(
      (event) => _current.add(event),
    );
    _currentAndNextSubscription = _queue.currentAndNext.listen(
      (event) => _currentAndNext.add(event),
    );
    _loopingSubscription = _queue.looping.listen((loop) {
      _looping.add(loop);
    });

    _looping.add(_queue.looping.value);
    _current.add(_queue.current.value);
    _currentAndNext.add(_queue.currentAndNext.value);
    notifyListeners();
  }

  @override
  Future<void> setLoop(bool loop) {
    return _queue.setLoop(loop);
  }

  @override
  Future<void> add(Song song, bool priority) {
    return _queue.add(song, priority);
  }

  @override
  Future<void> addAll(Iterable<Song> songs, bool priority) {
    return _queue.addAll(songs, priority);
  }

  @override
  Future<void> advance() {
    return _queue.advance();
  }

  @override
  Future<bool> get canAdvance => _queue.canAdvance;

  @override
  Future<bool> get canGoBack => _queue.canGoBack;

  @override
  Future<void> clear({
    bool queue = true,
    int fromIndex = 0,
    bool priorityQueue = true,
  }) {
    return _queue.clear(
      queue: queue,
      fromIndex: fromIndex,
      priorityQueue: priorityQueue,
    );
  }

  @override
  Future<int> get currentIndex => _queue.currentIndex;

  @override
  Future<void> goTo(int index) {
    return _queue.goTo(index);
  }

  @override
  Future<void> goToPriority(int index) {
    return _queue.goToPriority(index);
  }

  @override
  Future<void> insert(int index, Song song, bool priority) {
    return _queue.insert(index, song, priority);
  }

  @override
  Future<void> insertAll(int index, Iterable<Song> songs, bool priority) {
    return _queue.insertAll(index, songs, priority);
  }

  @override
  Future<int> get length => _queue.length;

  @override
  Future<int> get priorityLength => _queue.priorityLength;

  @override
  Future<void> remove(int index) {
    return _queue.remove(index);
  }

  @override
  Future<void> removeFromPriorityQueue(int index) {
    return _queue.removeFromPriorityQueue(index);
  }

  @override
  Future<void> replace(Iterable<Song> songs, [int startIndex = 0]) {
    return _queue.replace(songs, startIndex);
  }

  @override
  Future<void> shuffleFollowing() {
    return _queue.shuffleFollowing();
  }

  @override
  Future<void> shufflePriority() {
    return _queue.shufflePriority();
  }

  @override
  Future<void> skipNext() {
    return _queue.skipNext();
  }

  @override
  Future<void> skipPrev() {
    return _queue.skipPrev();
  }

  @override
  Future<Iterable<Song>> getRegularSongs({int? limit, int offset = 0}) {
    return _queue.getRegularSongs(limit: limit, offset: offset);
  }

  @override
  Future<Iterable<Song>> getPrioritySongs({int? limit, int offset = 0}) {
    return _queue.getPrioritySongs(limit: limit, offset: offset);
  }
}
