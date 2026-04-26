/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/audio/casting/device.dart';
import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:flutter/material.dart';

class CastingViewModel extends ChangeNotifier {
  final PlaybackManager _playbackManager;

  Device? _currentDevice;

  Device? get currentDevice => _currentDevice;

  List<Device> _discoveredDevices = [];

  List<Device> get discoveredDevices => _discoveredDevices;

  CastingViewModel({required PlaybackManager playbackManager})
    : _playbackManager = playbackManager {
    _playbackManager.deviceManager.addListener(_onDevicesChanged);
    _onDevicesChanged();
  }

  Future<void> _onDevicesChanged() async {
    _discoveredDevices = _playbackManager.deviceManager.devices.toList();
    final activeIndex = _discoveredDevices.indexWhere(
      (device) => _playbackManager.player.device == device,
    );
    if (activeIndex == -1) {
      _currentDevice = null;
    } else {
      _currentDevice = _discoveredDevices.removeAt(activeIndex);
    }

    notifyListeners();
  }

  Future<void> startDiscovery() async {
    await _playbackManager.deviceManager.startDiscovery();
  }

  Future<void> selectDevice(Device device) async {
    await _playbackManager.changeDevice(device);
    await _onDevicesChanged();
  }

  @override
  void dispose() {
    _playbackManager.deviceManager.removeListener(_onDevicesChanged);
    _playbackManager.deviceManager.stopDiscovery();
    super.dispose();
  }
}
