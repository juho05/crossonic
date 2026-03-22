/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:json_annotation/json_annotation.dart';

part 'item_date_model.g.dart';

@JsonSerializable()
class ItemDateModel {
  final int? year;
  final int? month;
  final int? day;

  ItemDateModel({required this.year, required this.month, required this.day});

  factory ItemDateModel.fromJson(Map<String, dynamic> json) =>
      _$ItemDateModelFromJson(json);

  Map<String, dynamic> toJson() => _$ItemDateModelToJson(this);
}
