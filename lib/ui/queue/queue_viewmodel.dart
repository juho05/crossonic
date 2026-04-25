/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:math';

import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/data/repositories/audio/queue/queue.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:flutter/material.dart';

class QueueViewModel extends ChangeNotifier {
  static const int _pageSize = 500;
  static const int _pageBuffer = 50;

  final PlaybackManager _playbackManager;
  late final StreamSubscription _currentSubscription;

  Song? _currentSong;

  Song? get currentSong => _currentSong;

  List<Song> _queue = [];
  List<Song> _priorityQueue = [];

  int? _reorderQueueLengthOverride;
  int? _reorderPrioQueueLengthOverride;

  int get queueLength =>
      _reorderQueueLengthOverride ??
      max(
        _playbackManager.queue.length - _playbackManager.queue.currentIndex - 1,
        0,
      );

  int get prioQueueLength =>
      _reorderPrioQueueLengthOverride ?? _playbackManager.queue.priorityLength;

  bool _reordering = false;

  DateTime _queueLastChanged = DateTime.now();

  Queue? _currentQueue;

  String get currentQueueName => _currentQueue?.name ?? "Default";

  bool get isDefaultQueue => _currentQueue?.isDefault ?? true;

  QueueViewModel({required PlaybackManager playbackManager})
    : _playbackManager = playbackManager {
    _playbackManager.queue.addListener(_queueChanged);
    _currentSubscription = _playbackManager.queue.current.listen(
      _currentChanged,
    );
    _queueChanged().then((value) {
      _currentChanged(_playbackManager.queue.current.value);
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

    final songs = await _playbackManager.queue.getRegularSongs(
      limit: _pageSize,
      offset: _playbackManager.queue.currentIndex + 1 + _queue.length,
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

    final songs = await _playbackManager.queue.getPrioritySongs(
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
    await _playbackManager.queue.clear(
      priorityQueue: false,
      fromIndex: _playbackManager.queue.currentIndex + 1,
    );
  }

  Future<void> clearPriorityQueue() async {
    await _playbackManager.queue.clear(queue: false);
  }

  Future<void> shuffleQueue() async {
    await _playbackManager.queue.shuffleFollowing();
  }

  Future<void> shufflePriorityQueue() async {
    await _playbackManager.queue.shufflePriority();
  }

  Future<void> remove(int index) async {
    if (_isPriorityQueue(index)) {
      await _playbackManager.queue.removeFromPriorityQueue(index);
    } else {
      await _playbackManager.queue.remove(_toQueueIndex(index));
    }
  }

  Future<void> goto(int index) async {
    _playbackManager.player.playOnNextMediaChange();
    if (_isPriorityQueue(index)) {
      await _playbackManager.queue.goToPriority(index);
    } else {
      await _playbackManager.queue.goTo(_toQueueIndex(index));
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
      await _playbackManager.queue.removeFromPriorityQueue(oldIndex);
    } else if (oldIsQueue) {
      await _playbackManager.queue.remove(_toQueueIndex(oldIndex));
    }

    if (newIsPrio) {
      await _playbackManager.queue.insert(newIndex, song, true);
    } else if (newIsQueue) {
      await _playbackManager.queue.insert(_toQueueIndex(newIndex), song, false);
    }

    _reordering = false;
    _queueChanged();
  }

  Future<Iterable<Song>> getAllSongs() async {
    return await _playbackManager.queue.getRegularSongs();
  }

  Future<void> _queueChanged() async {
    if (_reordering) return;
    if (_playbackManager.queue.currentQueueId != _currentQueue?.id) {
      _currentQueue = await _playbackManager.queue.getCurrentQueue();
    }
    final queue = (await _playbackManager.queue.getRegularSongs(
      limit: max(_pageSize, _queue.length),
      offset: _playbackManager.queue.currentIndex + 1,
    )).toList();
    final prioQueue = (await _playbackManager.queue.getPrioritySongs(
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
    index -= _playbackManager.queue.priorityLength + 1;
    return _playbackManager.queue.currentIndex + index + 1;
  }

  bool _isPriorityQueue(int index) => index < prioQueueLength;

  bool _isQueue(int index) => index > prioQueueLength;

  @override
  Future<void> dispose() async {
    await _currentSubscription.cancel();
    _playbackManager.queue.removeListener(_queueChanged);
    super.dispose();
  }
}
