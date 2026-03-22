/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/services/opensubsonic/models/albumid3_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'album_versions_model.g.dart';

@JsonSerializable()
class AlbumVersionsModel {
  final List<AlbumID3Model>? album;

  AlbumVersionsModel({required this.album});

  factory AlbumVersionsModel.fromJson(Map<String, dynamic> json) =>
      _$AlbumVersionsModelFromJson(json);

  Map<String, dynamic> toJson() => _$AlbumVersionsModelToJson(this);
}
