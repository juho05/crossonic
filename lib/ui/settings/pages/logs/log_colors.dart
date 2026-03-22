/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

const Map<Level, Color> levelColors = {
  Level.trace: Colors.grey,
  Level.debug: Colors.green,
  Level.info: Colors.blue,
  Level.warning: Colors.amber,
  Level.error: Colors.red,
  Level.fatal: Colors.purpleAccent,
};
