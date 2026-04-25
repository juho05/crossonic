/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:collection';

import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/data/repositories/audio/queue/queue.dart';
import 'package:flutter/foundation.dart';

class SelectQueueViewModel extends ChangeNotifier {
  final PlaybackManager _playbackManager;

  List<Queue> _queues = [];

  List<Queue> get queues => UnmodifiableListView(_queues);

  String get currentQueueId => _playbackManager.queue.currentQueueId;

  String _filter = "";

  set filter(String filter) {
    _filter = filter;
    _loadQueues();
  }

  SelectQueueViewModel({required PlaybackManager playbackManager})
    : _playbackManager = playbackManager {
    _playbackManager.queue.addListener(_loadQueues);
    _loadQueues();
  }

  Future<void> _loadQueues() async {
    final queues = await _playbackManager.queue.getQueues(filter: _filter);

    // move default queue to top
    final defaultIndex = queues.indexWhere((q) => q.isDefault);
    if (defaultIndex >= 0) {
      final defaultQueue = queues.removeAt(defaultIndex);
      queues.insert(0, defaultQueue);
    }

    // move current queue to top
    final currentIndex = queues.indexWhere((q) => q.id == currentQueueId);
    if (currentIndex >= 0) {
      final currentQueue = queues.removeAt(currentIndex);
      queues.insert(0, currentQueue);
    }

    _queues = queues;

    notifyListeners();
  }

  Future<void> selectQueue(Queue queue) async {
    await _playbackManager.queue.switchQueue(queue.id);
  }

  Future<void> deleteQueue(Queue queue) async {
    await _playbackManager.queue.deleteQueue(queue.id);
  }

  @override
  void dispose() {
    _playbackManager.queue.removeListener(_loadQueues);
    super.dispose();
  }
}
