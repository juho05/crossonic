import 'package:json_annotation/json_annotation.dart';

part 'scan_status_model.g.dart';

@JsonSerializable()
class ScanStatus {
  final bool scanning;
  final int? count;

  ScanStatus({
    required this.scanning,
    required this.count,
  });

  factory ScanStatus.fromJson(Map<String, dynamic> json) =>
      _$ScanStatusFromJson(json);
}
