/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:json_annotation/json_annotation.dart';

part 'opensubsonic_extension_model.g.dart';

@JsonSerializable()
class OpenSubsonicExtensionModel {
  final String name;
  final List<int> versions;

  OpenSubsonicExtensionModel({required this.name, required this.versions});

  factory OpenSubsonicExtensionModel.fromJson(Map<String, dynamic> json) =>
      _$OpenSubsonicExtensionModelFromJson(json);

  Map<String, dynamic> toJson() => _$OpenSubsonicExtensionModelToJson(this);

  @override
  String toString() {
    return "$name: ${versions.join(", ")}";
  }
}
