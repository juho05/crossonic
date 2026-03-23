/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:flutter/foundation.dart';

class VersionCheckingSettings extends ChangeNotifier {
  final KeyValueRepository _repo;

  static bool get externallyDisabled {
    if (!kIsWeb &&
        Platform.environment["CROSSONIC_DISABLE_VERSION_CHECK"] == "1") {
      return true;
    }
    if (!const bool.fromEnvironment("VERSION_CHECK", defaultValue: true)) {
      return true;
    }
    return false;
  }

  static const String _enabledKey = "version_checking.enabled";
  static bool get _enabledDefault => !externallyDisabled;

  bool _enabled = _enabledDefault;
  bool get enabled => _enabled;

  VersionCheckingSettings({required KeyValueRepository keyValueRepository})
    : _repo = keyValueRepository;

  Future<void> load() async {
    Log.trace("loading version checking settings");
    _enabled =
        (await _repo.loadBool(_enabledKey) ?? _enabledDefault) &&
        !externallyDisabled;
    notifyListeners();
  }

  void reset() {
    Log.debug("resetting version checking settings");
    _enabled = _enabledDefault;
    notifyListeners();
    _repo.remove(_enabledKey);
  }

  set enabled(bool enabled) {
    if (enabled == _enabled || externallyDisabled) return;
    Log.debug("version checking enabled: $enabled");
    _enabled = enabled;
    notifyListeners();
    _repo.store(_enabledKey, enabled);
  }
}
