/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/subsonic/models/helpers.dart';
import 'package:crossonic/data/services/opensubsonic/models/artist_info2_model.dart';

class ArtistInfo {
  final String? description;

  ArtistInfo({required this.description});

  factory ArtistInfo.fromArtistInfo2Model(ArtistInfo2Model a) {
    return ArtistInfo(description: emptyToNull(a.biography));
  }
}
