/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

class UpnpPositionInfo {
  final int track;
  final Duration trackDuration;
  final String trackUri;
  final Duration pos;
  final DateTime approximateTime;

  UpnpPositionInfo({
    required this.track,
    required this.trackDuration,
    required this.trackUri,
    required this.pos,
    required this.approximateTime,
  });
}
