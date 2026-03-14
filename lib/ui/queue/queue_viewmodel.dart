import 'dart:async';

import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:flutter/material.dart';

class QueueViewModel extends ChangeNotifier {
  final AudioHandler _audioHandler;
  late final StreamSubscription _currentSubscription;

  Song? _currentSong;
  Song? get currentSong => _currentSong;

  List<Song> _queue = [];
  List<Song> get queue => _queue;

  List<Song> _priorityQueue = [];
  List<Song> get priorityQueue => _priorityQueue;

  bool _reordering = false;

  QueueViewModel({required AudioHandler audioHandler})
    : _audioHandler = audioHandler {
    _audioHandler.queue.addListener(_queueChanged);
    _currentSubscription = _audioHandler.queue.current.listen(_currentChanged);
    _queueChanged().then((value) {
      _currentChanged(_audioHandler.queue.current.value);
    });
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
    _reordering = true;

    final Song song;

    // local reorder
    if (_isPriorityQueue(oldIndex)) {
      song = _priorityQueue.removeAt(oldIndex);
    } else if (_isQueue(oldIndex)) {
      song = _queue.removeAt(oldIndex - priorityQueue.length - 1);
    } else {
      return;
    }

    if (oldIndex < newIndex) {
      newIndex--;
    }

    if (_isPriorityQueue(newIndex - 1)) {
      _priorityQueue.insert(newIndex, song);
    } else if (_isQueue(newIndex)) {
      _queue.insert(newIndex - priorityQueue.length - 1, song);
    }

    notifyListeners();

    // actual reorder
    if (_isPriorityQueue(oldIndex)) {
      await _audioHandler.queue.removeFromPriorityQueue(oldIndex);
    } else if (_isQueue(oldIndex)) {
      await _audioHandler.queue.remove(_toQueueIndex(oldIndex));
    }

    if (_isPriorityQueue(newIndex - 1)) {
      await _audioHandler.queue.insert(newIndex, song, true);
    } else if (_isQueue(newIndex)) {
      await _audioHandler.queue.insert(_toQueueIndex(newIndex), song, false);
    }

    _reordering = false;
    _queueChanged();
  }

  Future<void> _queueChanged() async {
    if (_reordering) return;
    _queue = (await _audioHandler.queue.getRegularSongs(
      offset: _audioHandler.queue.currentIndex + 1,
    )).toList();
    _priorityQueue = (await _audioHandler.queue.getPrioritySongs()).toList();
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

  bool _isPriorityQueue(int index) =>
      index < _audioHandler.queue.priorityLength;
  bool _isQueue(int index) => index > _audioHandler.queue.priorityLength;

  @override
  Future<void> dispose() async {
    await _currentSubscription.cancel();
    _audioHandler.queue.removeListener(_queueChanged);
    super.dispose();
  }
}
