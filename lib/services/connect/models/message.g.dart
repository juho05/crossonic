// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Message',
      json,
      ($checkedConvert) {
        final val = Message(
          op: $checkedConvert('op', (v) => v as String),
          type: $checkedConvert('type', (v) => v as String),
          source: $checkedConvert('source', (v) => v as String? ?? ""),
          target: $checkedConvert('target', (v) => v as String),
          payload:
              $checkedConvert('payload', (v) => v as Map<String, dynamic>?),
        );
        return val;
      },
    );

Map<String, dynamic> _$MessageToJson(Message instance) {
  final val = <String, dynamic>{
    'op': instance.op,
    'type': instance.type,
    'source': instance.source,
    'target': instance.target,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('payload', instance.payload);
  return val;
}
