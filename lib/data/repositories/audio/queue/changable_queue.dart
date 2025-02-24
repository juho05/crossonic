import 'dart:async';

import 'package:crossonic/data/repositories/audio/queue/media_queue.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class ChangableQueue extends ChangeNotifier implements MediaQueue {
  MediaQueue _queue;
  StreamSubscription? _currentSubscription;
  StreamSubscription? _nextSubscription;
  StreamSubscription? _loopingSubscription;

  final BehaviorSubject<({bool fromAdvance, Song? song})> _current;
  @override
  ValueStream<({bool fromAdvance, Song? song})> get current => _current.stream;

  final BehaviorSubject<Song?> _next;
  @override
  ValueStream<Song?> get next => _next.stream;

  final BehaviorSubject<bool> _looping;
  @override
  ValueStream<bool> get looping => _looping.stream;

  ChangableQueue(MediaQueue queue)
      : _queue = queue,
        _current = BehaviorSubject.seeded(queue.current.value),
        _next = BehaviorSubject.seeded(queue.next.value),
        _looping = BehaviorSubject.seeded(queue.looping.value) {
    change(queue);
  }

  Future<void> change(MediaQueue queue) async {
    _queue.removeListener(notifyListeners);
    await _nextSubscription?.cancel();
    await _currentSubscription?.cancel();
    await _loopingSubscription?.cancel();

    _queue = queue;

    _queue.addListener(notifyListeners);
    _currentSubscription =
        _queue.current.listen((event) => _current.add(event));
    _nextSubscription = _queue.next.listen((event) => _next.add(event));
    _loopingSubscription = _queue.looping.listen((loop) => _looping.add(loop));
  }

  @override
  void setLoop(bool loop) {
    _queue.setLoop(loop);
  }

  @override
  void add(Song song, bool priority) {
    _queue.add(song, priority);
  }

  @override
  void addAll(Iterable<Song> songs, bool priority) {
    _queue.addAll(songs, priority);
  }

  @override
  void advance() {
    _queue.advance();
  }

  @override
  bool get canAdvance => _queue.canAdvance;

  @override
  bool get canGoBack => _queue.canGoBack;

  @override
  void clear(
      {bool queue = true, int fromIndex = 0, bool priorityQueue = true}) {
    _queue.clear(
        queue: queue, fromIndex: fromIndex, priorityQueue: priorityQueue);
  }

  @override
  int get currentIndex => _queue.currentIndex;

  @override
  void goTo(int index) {
    _queue.goTo(index);
  }

  @override
  void goToPriority(int index) {
    _queue.goToPriority(index);
  }

  @override
  void insert(int index, Song song) {
    _queue.insert(index, song);
  }

  @override
  void insertAll(int index, Iterable<Song> songs) {
    _queue.insertAll(index, songs);
  }

  @override
  int get length => _queue.length;

  @override
  Iterable<Song> get priority => _queue.priority;

  @override
  int get priorityLength => _queue.priorityLength;

  @override
  Iterable<Song> get regular => _queue.regular;

  @override
  void remove(int index) {
    _queue.remove(index);
  }

  @override
  void removeFromPriorityQueue(int index) {
    _queue.removeFromPriorityQueue(index);
  }

  @override
  void replace(Iterable<Song> songs, [int startIndex = 0]) {
    _queue.replace(songs, startIndex);
  }

  @override
  void shuffleFollowing() {
    _queue.shuffleFollowing();
  }

  @override
  void shufflePriority() {
    _queue.shufflePriority();
  }

  @override
  void skipNext() {
    _queue.skipNext();
  }

  @override
  void skipPrev() {
    _queue.skipPrev();
  }
}
