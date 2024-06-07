// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter

part of 'speaker_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpeakerState _$SpeakerStateFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SpeakerState',
      json,
      ($checkedConvert) {
        final val = SpeakerState(
          state: $checkedConvert('state', (v) => v as String),
          positionMs: $checkedConvert('positionMs', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$SpeakerStateToJson(SpeakerState instance) =>
    <String, dynamic>{
      'state': instance.state,
      'positionMs': instance.positionMs,
    };
