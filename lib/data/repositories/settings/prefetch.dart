/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math';

import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:flutter/foundation.dart';

class PrefetchSettings extends ChangeNotifier {
  static const String _enabledKey = "prefetch.enabled";
  static const String _countKey = "prefetch.count";

  static const int countMin = 2;
  static const int _countDefault = 5;

  final KeyValueRepository _repo;

  bool _enabled = false;

  bool get enabled => _enabled;

  int _count = _countDefault;

  int get count => _count;

  PrefetchSettings({required KeyValueRepository keyValueRepository})
    : _repo = keyValueRepository;

  Future<void> load() async {
    Log.trace("loading prefetch settings");
    _enabled = await _repo.loadBool(_enabledKey) ?? false;
    _count = max(countMin, await _repo.loadInt(_countKey) ?? _countDefault);
    notifyListeners();
  }

  set enabled(bool enabled) {
    if (_enabled == enabled) return;
    Log.debug("prefetch enabled setting: $enabled");
    _enabled = enabled;
    notifyListeners();
    _repo.store(_enabledKey, enabled);
  }

  set count(int count) {
    count = max(countMin, count);
    if (_count == count) return;
    Log.debug("prefetch count setting: $count");
    _count = count;
    notifyListeners();
    _repo.store(_countKey, count);
  }

  void reset() {
    Log.debug("resetting prefetching settings");
    _count = _countDefault;
    _enabled = false;
    notifyListeners();
    _repo.remove(_enabledKey);
    _repo.remove(_countKey);
  }
}
