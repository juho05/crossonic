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

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'op': instance.op,
      'type': instance.type,
      'source': instance.source,
      'target': instance.target,
      if (instance.payload case final value?) 'payload': value,
    };
