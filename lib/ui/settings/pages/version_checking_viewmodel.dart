/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/settings/version_checking.dart';
import 'package:crossonic/data/repositories/version/version.dart';
import 'package:crossonic/data/repositories/version/version_repository.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class VersionCheckingViewModel extends ChangeNotifier {
  final VersionCheckingSettings _settings;
  final VersionRepository _repository;

  bool _enabled = true;
  bool get enabled => _enabled;

  bool _checking = false;
  bool get checking => _checking;

  VersionCheckingViewModel({
    required VersionCheckingSettings settings,
    required VersionRepository repository,
  }) : _settings = settings,
       _repository = repository {
    _settings.addListener(_onSettingsChanged);
    _onSettingsChanged();
  }

  void _onSettingsChanged() {
    _enabled = _settings.enabled;
    notifyListeners();
  }

  void updateEnabled(bool enabled) {
    _settings.enabled = enabled;
  }

  Future<Result<({Version current, Version? latest})>> check() async {
    _checking = true;
    notifyListeners();
    try {
      final current = await VersionRepository.getCurrentVersion();
      final latestResult = await _repository.getLatestVersion(force: true);
      if (latestResult is Err) {
        return Result.error((latestResult as Err).error);
      }
      return Result.ok((current: current, latest: latestResult.tryValue));
    } finally {
      _checking = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
