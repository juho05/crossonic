/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/services/opensubsonic/models/albumid3_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/artistid3_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/child_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'starred2_model.g.dart';

@JsonSerializable()
class Starred2Model {
  final List<ArtistID3Model>? artist;
  final List<AlbumID3Model>? album;
  final List<ChildModel>? song;

  Starred2Model({
    required this.song,
    required this.album,
    required this.artist,
  });

  factory Starred2Model.fromJson(Map<String, dynamic> json) =>
      _$Starred2ModelFromJson(json);

  Map<String, dynamic> toJson() => _$Starred2ModelToJson(this);
}
