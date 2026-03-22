/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/services/opensubsonic/models/structured_lyrics_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lyrics_list_model.g.dart';

@JsonSerializable()
class LyricsListModel {
  final List<StructuredLyricsModel>? structuredLyrics;

  LyricsListModel({required this.structuredLyrics});

  factory LyricsListModel.fromJson(Map<String, dynamic> json) =>
      _$LyricsListModelFromJson(json);

  Map<String, dynamic> toJson() => _$LyricsListModelToJson(this);
}
