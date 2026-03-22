/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:json_annotation/json_annotation.dart';

part 'album_info_model.g.dart';

@JsonSerializable()
class AlbumInfoModel {
  final String? notes;
  final String? musicBrainzId;
  final String? lastFmUrl;
  final String? smallImageUrl;
  final String? mediumImageUrl;
  final String? largeImageUrl;

  AlbumInfoModel({
    required this.notes,
    required this.musicBrainzId,
    required this.lastFmUrl,
    required this.smallImageUrl,
    required this.mediumImageUrl,
    required this.largeImageUrl,
  });

  factory AlbumInfoModel.fromJson(Map<String, dynamic> json) =>
      _$AlbumInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$AlbumInfoModelToJson(this);
}
