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
