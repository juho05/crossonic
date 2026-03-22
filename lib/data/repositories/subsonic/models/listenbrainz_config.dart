/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/services/opensubsonic/models/listenbrainz_config_model.dart';

class ListenBrainzConfig {
  final String? username;
  final bool scrobble;
  final bool syncFeedback;

  ListenBrainzConfig({
    required this.username,
    required this.scrobble,
    required this.syncFeedback,
  });

  factory ListenBrainzConfig.fromListenBrainzConfigModel(
    ListenBrainzConfigModel l,
  ) {
    return ListenBrainzConfig(
      username: l.listenBrainzUsername,
      scrobble: l.scrobble ?? false,
      syncFeedback: l.syncFeedback ?? false,
    );
  }
}
