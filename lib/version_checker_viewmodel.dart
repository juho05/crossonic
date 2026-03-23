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
import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:crossonic/data/repositories/version/version.dart';
import 'package:crossonic/data/repositories/version/version_repository.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/foundation.dart';

class VersionCheckerViewModel extends ChangeNotifier {
  static const String _keyLastDisplayedDialog = "version.last_displayed_dialog";
  static const String _keyIgnoreVersion = "version.ignore_version";
  static const String _keyCurrentVersion = "version.current";

  final KeyValueRepository _keyValue;
  final SettingsRepository _settings;
  final VersionRepository _versionRepo;

  bool _checked = false;

  Version? _current;
  Version? get current => _current;
  Version? _latest;
  Version? get latest => _latest;
  bool get newVersionAvailable => _current != null && _latest != null;

  bool isOpen = false;
  bool showUpdateSuccessful = false;

  VersionCheckerViewModel({
    required KeyValueRepository keyValue,
    required VersionRepository versionRepo,
    required SettingsRepository settings,
  }) : _keyValue = keyValue,
       _versionRepo = versionRepo,
       _settings = settings {
    if (!kIsWeb) {
      _checked = Platform.environment["CROSSONIC_DISABLE_VERSION_CHECK"] == "1";
    } else {
      _checked = true;
    }
    if (const bool.hasEnvironment("VERSION_CHECK")) {
      _checked = !const bool.fromEnvironment("VERSION_CHECK");
    }
    if (!_settings.versionChecking.enabled) {
      _checked = true;
    }
    if (_checked) {
      Log.info("version checking is disabled");
    }
  }

  Future<void> check() async {
    if (_checked) return;
    _checked = true;

    _current = await VersionRepository.getCurrentVersion();
    final prevCurrent = await _keyValue.loadObject(
      _keyCurrentVersion,
      Version.fromJson,
    );
    if (prevCurrent != null && _current! > prevCurrent) {
      showUpdateSuccessful = true;
      notifyListeners();
    }
    if (prevCurrent != _current) {
      await _keyValue.store(_keyCurrentVersion, current!);
    }

    final lastDisplayed = await _keyValue.loadDateTime(_keyLastDisplayedDialog);
    if (lastDisplayed != null &&
        DateTime.now().difference(lastDisplayed) < const Duration(days: 1)) {
      return;
    }

    final latest = await _versionRepo.getLatestVersion();
    switch (latest) {
      case Err():
        Log.error("Check new version available", e: latest.error);
      case Ok():
    }
    if (latest.tryValue == null) {
      Log.warn("No latest version found");
      return;
    }
    final ignoreVersion = await _keyValue.loadString(_keyIgnoreVersion);
    if (ignoreVersion != null &&
        Version.parse(ignoreVersion) == latest.tryValue) {
      Log.trace("Ignored latest version: $ignoreVersion");
      return;
    }
    await _keyValue.remove(_keyIgnoreVersion);

    Log.debug("[Version check] latest: ${latest.tryValue}; current: $_current");

    if (latest.tryValue! > _current!) {
      _latest = latest.tryValue;
      notifyListeners();
    }
  }

  Future<void> displayedVersionDialog() async {
    isOpen = false;
    _current = null;
    _latest = null;
    await _keyValue.store(_keyLastDisplayedDialog, DateTime.now());
  }

  Future<void> ignoreVersion() async {
    if (_latest == null) return;
    await _keyValue.store(_keyIgnoreVersion, _latest.toString());
  }
}
