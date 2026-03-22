/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/services/opensubsonic/models/albumid3_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'album_list2_model.g.dart';

@JsonSerializable()
class AlbumList2Model {
  final List<AlbumID3Model>? album;
  AlbumList2Model({required this.album});

  factory AlbumList2Model.fromJson(Map<String, dynamic> json) =>
      _$AlbumList2ModelFromJson(json);

  Map<String, dynamic> toJson() => _$AlbumList2ModelToJson(this);
}
