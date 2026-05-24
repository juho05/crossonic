/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/utils/throttle.dart';
import 'package:flutter/material.dart';

class VolumeViewModel extends ChangeNotifier {
  final PlaybackManager _playbackManager;

  // cubic volume
  double _volume = 1;

  // cubic volume
  double get volume => _volume;

  Throttle1<double>? _volumeThrottle;

  set volume(double volume) {
    _volumeThrottle ??= Throttle1(
      action: (volume) {
        _playbackManager.player.volumeCubic = volume;
      },
      delay: const Duration(milliseconds: 100),
      leading: true,
      trailing: true,
    );
    _volume = volume;
    _volumeThrottle!.call(volume);
    notifyListeners();
  }

  StreamSubscription? _volumeSubscription;

  VolumeViewModel({required PlaybackManager playbackManager})
    : _playbackManager = playbackManager {
    _volume = _playbackManager.player.volumeCubic;
    _volumeSubscription = _playbackManager.player.volumeLinearStream.listen((
      _,
    ) {
      _volume = _playbackManager.player.volumeCubic;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _volumeSubscription?.cancel();
    super.dispose();
  }
}
