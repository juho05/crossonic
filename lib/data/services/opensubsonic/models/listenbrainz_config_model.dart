/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:json_annotation/json_annotation.dart';

part 'listenbrainz_config_model.g.dart';

@JsonSerializable()
class ListenBrainzConfigModel {
  final String? listenBrainzUsername;
  final bool? scrobble;
  final bool? syncFeedback;

  ListenBrainzConfigModel({
    required this.listenBrainzUsername,
    required this.scrobble,
    required this.syncFeedback,
  });

  factory ListenBrainzConfigModel.fromJson(Map<String, dynamic> json) =>
      _$ListenBrainzConfigModelFromJson(json);

  Map<String, dynamic> toJson() => _$ListenBrainzConfigModelToJson(this);
}
