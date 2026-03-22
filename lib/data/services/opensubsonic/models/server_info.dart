/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

class ServerInfo {
  final String subsonicVersion;

  final bool isOpenSubsonic;
  final String? serverVersion;
  final String? type;

  final bool isCrossonic;
  final String? crossonicVersion;

  bool get isNavidrome => type != null && type == "navidrome";

  ServerInfo({
    required this.serverVersion,
    required this.isOpenSubsonic,
    required this.subsonicVersion,
    required this.type,
    required this.isCrossonic,
    required this.crossonicVersion,
  });
}
