/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:json_annotation/json_annotation.dart';

part 'replay_gain_model.g.dart';

@JsonSerializable()
class ReplayGainModel {
  final double? trackGain;
  final double? albumGain;
  final double? trackPeak;
  final double? albumPeak;
  final double? baseGain;
  final double? fallbackGain;

  ReplayGainModel({
    required this.trackGain,
    required this.albumGain,
    required this.trackPeak,
    required this.albumPeak,
    required this.baseGain,
    required this.fallbackGain,
  });

  factory ReplayGainModel.fromJson(Map<String, dynamic> json) =>
      _$ReplayGainModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReplayGainModelToJson(this);
}
