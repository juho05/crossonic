/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:crossonic/data/repositories/audio/casting/device.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LocalDevice extends Device {
  @override
  String get name => "This device";

  @override
  String get type => "Local";

  @override
  List<String> get extraInfos => const [];

  @override
  IconData get icon => kIsWeb
      ? Icons.web_outlined
      : Platform.isAndroid || Platform.isIOS
      ? Icons.phone_android_outlined
      : Platform.isMacOS
      ? Icons.desktop_mac_outlined
      : Icons.desktop_windows_outlined;

  const LocalDevice();
}
