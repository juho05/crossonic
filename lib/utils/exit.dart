/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

Future<void> exitApp() async {
  if (kIsWeb) return;
  if (Platform.isWindows || Platform.isLinux) {
    await windowManager.setPreventClose(false);
    await windowManager.close();
  }
  exit(0);
}
