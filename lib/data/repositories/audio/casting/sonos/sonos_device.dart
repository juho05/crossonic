/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/audio/casting/device.dart';
import 'package:flutter/material.dart';

class SonosDevice implements Device {
  final String _name;
  final String _ipAddr;
  final String? _modelName;

  SonosDevice({required String name, required String ipAddr, String? modelName})
    : _name = name,
      _ipAddr = ipAddr,
      _modelName = modelName;

  @override
  String get name => _name;

  String? get modelName => _modelName;

  @override
  String get type => "Sonos";

  String get ipAddr => _ipAddr;

  @override
  List<String> get extraInfos => [if (_modelName != null) _modelName, ipAddr];

  @override
  IconData get icon => Icons.speaker_group_outlined;

  @override
  bool operator ==(Object other) {
    if (other is! SonosDevice) return false;
    return name == other.name && type == other.type && ipAddr == other.ipAddr;
  }

  @override
  int get hashCode => Object.hash(name, type, ipAddr);
}
