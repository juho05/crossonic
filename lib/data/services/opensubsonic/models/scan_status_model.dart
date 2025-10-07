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
