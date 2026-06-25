/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/settings/prefetch.dart';
import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:flutter/material.dart';

class PrefetchViewModel extends ChangeNotifier {
  final SettingsRepository _settings;

  bool _enabled;

  bool get enabled => _enabled;

  int _count;

  int get count => _count;

  int get minCount => PrefetchSettings.countMin;

  PrefetchViewModel({required SettingsRepository settings})
    : _settings = settings,
      _enabled = settings.prefetch.enabled,
      _count = settings.prefetch.count {
    _settings.prefetch.addListener(_onSettingsChanged);
  }

  set enabled(bool value) {
    if (value) {
      _settings.prefetch.enabled = true;
    } else {
      _settings.prefetch.reset();
    }
  }

  set count(int value) {
    _settings.prefetch.count = value;
  }

  void _onSettingsChanged() {
    _enabled = _settings.prefetch.enabled;
    _count = _settings.prefetch.count;
    notifyListeners();
  }

  @override
  void dispose() {
    _settings.prefetch.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
