// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter

part of 'item_date_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemDate _$ItemDateFromJson(Map<String, dynamic> json) => $checkedCreate(
      'ItemDate',
      json,
      ($checkedConvert) {
        final val = ItemDate(
          year: $checkedConvert('year', (v) => (v as num?)?.toInt()),
          month: $checkedConvert('month', (v) => (v as num?)?.toInt()),
          day: $checkedConvert('day', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$ItemDateToJson(ItemDate instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('year', instance.year);
  writeNotNull('month', instance.month);
  writeNotNull('day', instance.day);
  return val;
}
