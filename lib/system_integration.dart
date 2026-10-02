/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter_system_integration/flutter_system_integration.dart';

const systemIntegrationConfig = SystemIntegrationConfig(
  appName: "Crossonic",
  executableName: "crossonic",
  envPrefix: "CROSSONIC",
  githubOwner: "juho05",
  githubRepo: "crossonic",
  desktopId: "org.crossonic.app",
  desktopIconAsset: "assets/icon/desktop/crossonic-512.png",
  desktopCategories: ["Multimedia"],
);
