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

  QueueViewModel({
    required AudioHandler audioHandler,
  }) : _audioHandler = audioHandler {
    _audioHandler.queue.addListener(_queueChanged);
    _currentSubscription = _audioHandler.queue.current.listen(_currentChanged);
    _queueChanged();
  }

  void clearQueue() {
    _audioHandler.queue.clear(
        priorityQueue: false, fromIndex: _audioHandler.queue.currentIndex + 1);
  }

  void clearPriorityQueue() {
    _audioHandler.queue.clear(queue: false);
  }

  void shuffleQueue() {
    _audioHandler.queue.shuffleFollowing();
  }

  void shufflePriorityQueue() {
    _audioHandler.queue.shufflePriority();
  }

  void remove(int index) {
    if (_isPriorityQueue(index)) {
      _audioHandler.queue.removeFromPriorityQueue(index);
    } else {
      _audioHandler.queue.remove(_toQueueIndex(index));
    }
  }

  void addSongToQueue(Song song, bool priority) {
    _audioHandler.queue.add(song, priority);
  }

  void goto(int index) {
    _audioHandler.playOnNextMediaChange();
    if (_isPriorityQueue(index)) {
      _audioHandler.queue.goToPriority(index);
    } else {
      _audioHandler.queue.goTo(_toQueueIndex(index));
    }
  }

  void reorder(int oldIndex, int newIndex) {
    _reordering = true;
    final Song song;
    if (_isPriorityQueue(oldIndex)) {
      song = priorityQueue[oldIndex];
      _audioHandler.queue.removeFromPriorityQueue(oldIndex);
    } else if (_isQueue(oldIndex)) {
      song = queue[oldIndex - priorityQueue.length - 1];
      _audioHandler.queue.remove(_toQueueIndex(oldIndex));
    } else {
      return;
    }
    if (oldIndex < newIndex) {
      newIndex--;
    }
    if (_isPriorityQueue(newIndex - 1)) {
      _audioHandler.queue.insert(newIndex, song, true);
    } else if (_isQueue(newIndex)) {
      _audioHandler.queue.insert(_toQueueIndex(newIndex), song, false);
    }
    _reordering = false;
    _queueChanged();
  }

  void _queueChanged() {
    if (_reordering) return;
    _queue = _audioHandler.queue.regular
        .skip(_audioHandler.queue.currentIndex + 1)
        .toList();
    _priorityQueue = _audioHandler.queue.priority.toList();
    notifyListeners();
  }

  void _currentChanged(({bool fromAdvance, Song? song}) current) {
    _currentSong = current.song;
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
