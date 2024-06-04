// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter

part of 'device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Device _$DeviceFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Device',
      json,
      ($checkedConvert) {
        final val = Device(
          name: $checkedConvert('name', (v) => v as String),
          id: $checkedConvert('id', (v) => v as String),
          platform: $checkedConvert('platform', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$DeviceToJson(Device instance) => <String, dynamic>{
      'name': instance.name,
      'id': instance.id,
      'platform': instance.platform,
    };
