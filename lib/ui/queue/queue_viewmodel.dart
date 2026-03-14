import 'dart:async';
import 'dart:math';

import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:flutter/material.dart';

class QueueViewModel extends ChangeNotifier {
  static const int _pageSize = 500;
  static const int _pageBuffer = 50;

  final AudioHandler _audioHandler;
  late final StreamSubscription _currentSubscription;

  Song? _currentSong;
  Song? get currentSong => _currentSong;

  List<Song> _queue = [];
  List<Song> _priorityQueue = [];

  int? _reorderQueueLengthOverride;
  int? _reorderPrioQueueLengthOverride;

  int get queueLength =>
      _reorderQueueLengthOverride ??
      max(_audioHandler.queue.length - _audioHandler.queue.currentIndex - 1, 0);
  int get prioQueueLength =>
      _reorderPrioQueueLengthOverride ?? _audioHandler.queue.priorityLength;

  bool _reordering = false;

  DateTime _queueLastChanged = DateTime.now();

  QueueViewModel({required AudioHandler audioHandler})
    : _audioHandler = audioHandler {
    _audioHandler.queue.addListener(_queueChanged);
    _currentSubscription = _audioHandler.queue.current.listen(_currentChanged);
    _queueChanged().then((value) {
      _currentChanged(_audioHandler.queue.current.value);
    });
  }

  Song? getSong(int queueIndex) {
    if (queueIndex >= queueLength || queueIndex < 0) return null;

    if (queueIndex > _queue.length - _pageBuffer &&
        _queue.length < queueLength) {
      _fetchNextQueuePage();
    }

    return _queue.elementAtOrNull(queueIndex);
  }

  Song? getPrioSong(int prioQueueIndex) {
    if (prioQueueIndex >= prioQueueLength || prioQueueIndex < 0) return null;

    if (prioQueueIndex > _priorityQueue.length - _pageBuffer &&
        _priorityQueue.length < prioQueueLength) {
      _fetchNextPrioQueuePage();
    }

    return _priorityQueue.elementAtOrNull(prioQueueIndex);
  }

  bool _fetchingQueuePage = false;
  Future<void> _fetchNextQueuePage() async {
    if (_fetchingQueuePage) return;
    _fetchingQueuePage = true;

    final changedBefore = _queueLastChanged;

    final songs = await _audioHandler.queue.getRegularSongs(
      limit: _pageSize,
      offset: _audioHandler.queue.currentIndex + 1 + _queue.length,
    );

    if (changedBefore == _queueLastChanged) {
      _queue.addAll(songs);
    }

    _fetchingQueuePage = false;
    notifyListeners();
  }

  bool _fetchingPrioQueuePage = false;
  Future<void> _fetchNextPrioQueuePage() async {
    if (_fetchingPrioQueuePage) return;
    _fetchingPrioQueuePage = true;

    final changedBefore = _queueLastChanged;

    final songs = await _audioHandler.queue.getPrioritySongs(
      limit: _pageSize,
      offset: _priorityQueue.length,
    );

    if (changedBefore == _queueLastChanged) {
      _priorityQueue.addAll(songs);
    }

    _fetchingPrioQueuePage = false;
    notifyListeners();
  }

  Future<void> clearQueue() async {
    await _audioHandler.queue.clear(
      priorityQueue: false,
      fromIndex: _audioHandler.queue.currentIndex + 1,
    );
  }

  Future<void> clearPriorityQueue() async {
    await _audioHandler.queue.clear(queue: false);
  }

  Future<void> shuffleQueue() async {
    await _audioHandler.queue.shuffleFollowing();
  }

  Future<void> shufflePriorityQueue() async {
    await _audioHandler.queue.shufflePriority();
  }

  Future<void> remove(int index) async {
    if (_isPriorityQueue(index)) {
      await _audioHandler.queue.removeFromPriorityQueue(index);
    } else {
      await _audioHandler.queue.remove(_toQueueIndex(index));
    }
  }

  Future<void> goto(int index) async {
    _audioHandler.playOnNextMediaChange();
    if (_isPriorityQueue(index)) {
      _audioHandler.queue.goToPriority(index);
    } else {
      _audioHandler.queue.goTo(_toQueueIndex(index));
    }
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (_fetchingQueuePage || _fetchingPrioQueuePage) return;
    _reordering = true;

    bool oldIsPrio = _isPriorityQueue(oldIndex);
    bool oldIsQueue = _isQueue(oldIndex);

    bool newIsPrio = _isPriorityQueue(newIndex - 1);
    bool newIsQueue = _isQueue(newIndex);

    final Song song;

    // local reorder
    if (oldIsPrio) {
      song = _priorityQueue.removeAt(oldIndex);
      _reorderPrioQueueLengthOverride = prioQueueLength - 1;
    } else if (oldIsQueue) {
      song = _queue.removeAt(oldIndex - prioQueueLength - 1);
      _reorderQueueLengthOverride = queueLength - 1;
    } else {
      return;
    }

    if (oldIndex < newIndex) {
      newIndex--;
    }

    if (newIsPrio) {
      _priorityQueue.insert(newIndex, song);
      _reorderPrioQueueLengthOverride = prioQueueLength + 1;
    } else if (newIsQueue) {
      _queue.insert(newIndex - prioQueueLength - 1, song);
      _reorderQueueLengthOverride = queueLength + 1;
    }

    notifyListeners();

    // actual reorder
    if (oldIsPrio) {
      await _audioHandler.queue.removeFromPriorityQueue(oldIndex);
    } else if (oldIsQueue) {
      await _audioHandler.queue.remove(_toQueueIndex(oldIndex));
    }

    if (newIsPrio) {
      await _audioHandler.queue.insert(newIndex, song, true);
    } else if (newIsQueue) {
      await _audioHandler.queue.insert(_toQueueIndex(newIndex), song, false);
    }

    _reordering = false;
    _queueChanged();
  }

  Future<void> _queueChanged() async {
    if (_reordering) return;
    final queue = (await _audioHandler.queue.getRegularSongs(
      limit: max(_pageSize, _queue.length),
      offset: _audioHandler.queue.currentIndex + 1,
    )).toList();
    final prioQueue = (await _audioHandler.queue.getPrioritySongs(
      limit: max(_pageSize, _priorityQueue.length),
    )).toList();
    _queueLastChanged = DateTime.now();
    _queue = queue;
    _reorderQueueLengthOverride = null;
    _reorderPrioQueueLengthOverride = null;
    _priorityQueue = prioQueue;
    notifyListeners();
  }

  void _currentChanged(Song? song) {
    _currentSong = song;
    notifyListeners();
  }

  int _toQueueIndex(int index) {
    index -= _audioHandler.queue.priorityLength + 1;
    return _audioHandler.queue.currentIndex + index + 1;
  }

  bool _isPriorityQueue(int index) => index < prioQueueLength;
  bool _isQueue(int index) => index > prioQueueLength;

  @override
  Future<void> dispose() async {
    await _currentSubscription.cancel();
    _audioHandler.queue.removeListener(_queueChanged);
    super.dispose();
  }
}
