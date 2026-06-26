/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/version/version_repository.dart';
import 'package:flutter/material.dart';

class SettingsViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  bool _loggingOut = false;

  bool get loggingOut => _loggingOut;

  bool get supportsListenBrainz =>
      _authRepository.serverFeatures.value.isCrossonic;

  Future<String> get version async =>
      "v${(await VersionRepository.getCurrentVersion())}";

  SettingsViewModel({
    required this._authRepository,
    required VersionRepository versionRepository,
  });

  Future<void> logout() async {
    _loggingOut = true;
    notifyListeners();
    await _authRepository.logout(true);
  }
}
