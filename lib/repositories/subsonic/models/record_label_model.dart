import 'package:json_annotation/json_annotation.dart';

part 'record_label_model.g.dart';

@JsonSerializable()
class RecordLabel {
  final String name;

  RecordLabel({
    required this.name,
  });

  factory RecordLabel.fromJson(Map<String, dynamic> json) =>
      _$RecordLabelFromJson(json);
}
