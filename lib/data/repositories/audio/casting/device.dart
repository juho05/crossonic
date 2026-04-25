/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

abstract class Device {
  String get name;

  String get type;

  List<String> get extraInfos;

  const Device();

  @override
  bool operator ==(Object other) {
    if (other is! Device) return false;
    return name == other.name && type == other.type;
  }

  @override
  int get hashCode => Object.hash(name, type);
}
