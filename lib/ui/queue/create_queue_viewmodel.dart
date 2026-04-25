/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:flutter/material.dart';

class CreateQueueViewModel extends ChangeNotifier {
  final PlaybackManager _playbackManager;

  String _name = "";

  set name(String name) {
    _name = name;
    notifyListeners();
  }

  bool get isValid => _name.isNotEmpty;

  CreateQueueViewModel({required PlaybackManager playbackManager})
    : _playbackManager = playbackManager;

  Future<void> create() async {
    await _playbackManager.queue.createNewQueue(_name);
  }
}
