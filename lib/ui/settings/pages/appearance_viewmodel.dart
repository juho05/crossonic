/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/settings/appearance.dart';
import 'package:flutter/material.dart';

class AppearanceViewModel extends ChangeNotifier {
  final AppearanceSettings _settings;

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  bool _dynamicColors = false;
  bool get dynamicColors => _dynamicColors;

  AppearanceViewModel({required AppearanceSettings settings})
    : _settings = settings {
    _settings.addListener(_onSettingsChanged);
    _onSettingsChanged();
  }

  void _onSettingsChanged() {
    _mode = _settings.themeMode;
    _dynamicColors = _settings.dynamicColors;
    notifyListeners();
  }

  void updateMode(ThemeMode mode) {
    _settings.themeMode = mode;
  }

  void updateDynamicColors(bool enable) {
    _settings.dynamicColors = enable;
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
