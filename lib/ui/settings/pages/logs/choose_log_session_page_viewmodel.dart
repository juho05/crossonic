/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/logger/log_repository.dart';
import 'package:flutter/material.dart';

class ChooseLogSessionPageViewModel extends ChangeNotifier {
  final LogRepository _repository;

  List<DateTime> _sessions;
  List<DateTime> get sessions => _sessions;

  ChooseLogSessionPageViewModel({required LogRepository logRepository})
    : _repository = logRepository,
      _sessions = const [] {
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    _sessions = await _repository.getSessions();
    notifyListeners();
  }
}
