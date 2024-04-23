import 'package:json_annotation/json_annotation.dart';

part 'item_date_model.g.dart';

@JsonSerializable()
class ItemDate {
  final int? year;
  final int? month;
  final int? day;
  ItemDate({
    this.year,
    this.month,
    this.day,
  });

  factory ItemDate.fromJson(Map<String, dynamic> json) =>
      _$ItemDateFromJson(json);
}
