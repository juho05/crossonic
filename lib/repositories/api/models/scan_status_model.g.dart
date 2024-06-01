// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter

part of 'scan_status_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScanStatus _$ScanStatusFromJson(Map<String, dynamic> json) => $checkedCreate(
      'ScanStatus',
      json,
      ($checkedConvert) {
        final val = ScanStatus(
          scanning: $checkedConvert('scanning', (v) => v as bool),
          count: $checkedConvert('count', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$ScanStatusToJson(ScanStatus instance) {
  final val = <String, dynamic>{
    'scanning': instance.scanning,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('count', instance.count);
  return val;
}
