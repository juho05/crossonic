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
          year: $checkedConvert('year', (v) => v as int?),
          month: $checkedConvert('month', (v) => v as int?),
          day: $checkedConvert('day', (v) => v as int?),
        );
        return val;
      },
    );
