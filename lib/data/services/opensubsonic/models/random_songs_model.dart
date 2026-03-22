/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/services/opensubsonic/models/child_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'random_songs_model.g.dart';

@JsonSerializable()
class RandomSongsModel {
  final List<ChildModel>? song;

  RandomSongsModel({required this.song});

  factory RandomSongsModel.fromJson(Map<String, dynamic> json) =>
      _$RandomSongsModelFromJson(json);

  Map<String, dynamic> toJson() => _$RandomSongsModelToJson(this);
}
