/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/appimage/appimage_repository.dart';
import 'package:crossonic/data/services/restart/restart.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class AppImageSettingsViewModel extends ChangeNotifier {
  final AppImageRepository _repo;

  bool? _integrated;
  bool? get integrated => _integrated;

  AppImageSettingsViewModel({required AppImageRepository appImageRepository})
    : _repo = appImageRepository {
    _repo.isIntegrated().then((value) {
      _integrated = value;
      notifyListeners();
    });
  }

  Future<Result<void>> integrate() async {
    final result = await _repo.integrate();
    if (result is Ok) {
      Restart.restart();
    }
    return result;
  }
}
