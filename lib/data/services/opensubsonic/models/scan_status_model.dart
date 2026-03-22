/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/services/opensubsonic/models/datetime_converter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'scan_status_model.g.dart';

@JsonSerializable()
class ScanStatusModel {
  final bool scanning;
  final int? count;
  @DateTimeConverter()
  final DateTime? lastScan;
  @DateTimeConverter()
  final DateTime? startTime;
  final bool? fullScan;
  final String? scanType;

  bool? get isFullScan => fullScan != null || scanType != null
      ? (fullScan != null && fullScan!) ||
            (scanType != null && scanType! == "full")
      : null;

  ScanStatusModel({
    required this.scanning,
    required this.count,
    required this.lastScan,
    required this.startTime,
    required this.fullScan,
    required this.scanType,
  });

  factory ScanStatusModel.fromJson(Map<String, dynamic> json) =>
      _$ScanStatusModelFromJson(json);

  Map<String, dynamic> toJson() => _$ScanStatusModelToJson(this);
}
