/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:crossonic/data/repositories/audio/casting/device.dart';
import 'package:flutter/foundation.dart';

abstract class DeviceDiscoverer {
  @protected
  final StreamController<Device> discoveredController =
      StreamController.broadcast();

  Stream<Device> get discovered => discoveredController.stream;

  Future<void> startDiscovery();

  Future<void> stopDiscovery();
}
