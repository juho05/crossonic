/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:json_annotation/json_annotation.dart';

part 'token_info_model.g.dart';

@JsonSerializable()
class TokenInfoModel {
  final String username;

  TokenInfoModel({required this.username});

  factory TokenInfoModel.fromJson(Map<String, dynamic> json) =>
      _$TokenInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$TokenInfoModelToJson(this);
}
