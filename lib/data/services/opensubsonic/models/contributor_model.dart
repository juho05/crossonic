/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:json_annotation/json_annotation.dart';

part 'contributor_model.g.dart';

@JsonSerializable()
class ContributorModel {
  final String role;
  final String? subRole;
  final ({String id, String name}) artist;

  ContributorModel({
    required this.role,
    required this.subRole,
    required this.artist,
  });

  factory ContributorModel.fromJson(Map<String, dynamic> json) =>
      _$ContributorModelFromJson(json);

  Map<String, dynamic> toJson() => _$ContributorModelToJson(this);
}
