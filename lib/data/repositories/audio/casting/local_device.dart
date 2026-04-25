/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/audio/casting/device.dart';

class LocalDevice extends Device {
  @override
  String get name => "This device";

  @override
  String get type => "Local";

  @override
  List<String> get extraInfos => const [];

  const LocalDevice();
}
