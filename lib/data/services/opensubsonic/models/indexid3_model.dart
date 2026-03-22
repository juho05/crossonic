/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/services/opensubsonic/models/artistid3_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'indexid3_model.g.dart';

@JsonSerializable()
class IndexID3Model {
  final String name;
  final List<ArtistID3Model>? artist;

  IndexID3Model({required this.name, required this.artist});

  factory IndexID3Model.fromJson(Map<String, dynamic> json) =>
      _$IndexID3ModelFromJson(json);

  Map<String, dynamic> toJson() => _$IndexID3ModelToJson(this);
}
