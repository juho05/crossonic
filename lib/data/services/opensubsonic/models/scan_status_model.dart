import 'package:json_annotation/json_annotation.dart';

part 'scan_status_model.g.dart';

@JsonSerializable()
class ScanStatusModel {
  final bool scanning;
  final int? count;

  ScanStatusModel({
    required this.scanning,
    required this.count,
  });

  factory ScanStatusModel.fromJson(Map<String, dynamic> json) =>
      _$ScanStatusModelFromJson(json);
}
