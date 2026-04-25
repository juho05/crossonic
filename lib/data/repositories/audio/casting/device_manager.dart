/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:collection';

import 'package:crossonic/data/repositories/audio/casting/device.dart';
import 'package:crossonic/data/repositories/audio/casting/device_discoverer.dart';
import 'package:crossonic/data/repositories/audio/casting/local_device.dart';
import 'package:crossonic/data/repositories/audio/casting/sonos/sonos_discoverer.dart';
import 'package:crossonic/data/repositories/audio/players/player.dart';
import 'package:flutter/foundation.dart';

class DeviceManager extends ChangeNotifier {
  final List<DeviceDiscoverer> _discoverers = [SonosDiscoverer()];

  final List<Device> _devices = [const LocalDevice()];

  List<Device> get devices => UnmodifiableListView(_devices);

  bool _discovering = false;

  bool get discovering => _discovering;

  DeviceManager() {
    _registerDeviceStreams();
  }

  Future<void> startDiscovery() async {
    _discovering = true;
    notifyListeners();

    for (final d in _discoverers) {
      await d.startDiscovery();
    }
  }

  Future<void> stopDiscovery() async {
    _discovering = false;
    _devices.clear();
    _devices.add(const LocalDevice());
    notifyListeners();

    for (final d in _discoverers) {
      await d.stopDiscovery();
    }
  }

  Timer? _notifyListenersDebounce;

  void _registerDeviceStreams() {
    for (final d in _discoverers) {
      d.discovered.listen((device) {
        if (!_discovering) return;
        if (_devices.contains(device)) return;
        _devices.add(device);
        _notifyListenersDebounce?.cancel();
        _notifyListenersDebounce = Timer(
          const Duration(milliseconds: 250),
          () => notifyListeners(),
        );
      });
    }
  }

  Future<AudioPlayer> createPlayerFromDevice(Device device) {
    // TODO
    throw UnimplementedError();
  }
}
