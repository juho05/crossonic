/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

class Queue {
  final String id;
  final String name;
  final int songCount;
  final int currentIndex;
  final bool isDefault;

  Queue({
    required this.id,
    required this.name,
    required this.songCount,
    required this.currentIndex,
    required this.isDefault,
  });
}
