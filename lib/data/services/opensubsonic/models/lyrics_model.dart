/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:json_annotation/json_annotation.dart';

part 'lyrics_model.g.dart';

@JsonSerializable()
class LyricsModel {
  final String value;
  final String? artist;
  final String? title;

  LyricsModel({required this.artist, required this.title, required this.value});

  factory LyricsModel.fromJson(Map<String, dynamic> json) =>
      _$LyricsModelFromJson(json);

  Map<String, dynamic> toJson() => _$LyricsModelToJson(this);
}
