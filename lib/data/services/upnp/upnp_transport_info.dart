/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

enum UpnpTransportState {
  stopped,
  playing,
  pausedPlayback,
  transitioning,
  unknown,
}

class UpnpTransportInfo {
  final UpnpTransportState state;
  final String? status;
  final double? speed;

  UpnpTransportInfo({
    required this.state,
    required this.status,
    required this.speed,
  });
}
