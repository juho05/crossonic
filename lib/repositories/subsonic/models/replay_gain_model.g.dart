// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter

part of 'replay_gain_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReplayGain _$ReplayGainFromJson(Map<String, dynamic> json) => $checkedCreate(
      'ReplayGain',
      json,
      ($checkedConvert) {
        final val = ReplayGain(
          trackGain:
              $checkedConvert('trackGain', (v) => (v as num?)?.toDouble()),
          albumGain:
              $checkedConvert('albumGain', (v) => (v as num?)?.toDouble()),
          trackPeak:
              $checkedConvert('trackPeak', (v) => (v as num?)?.toDouble()),
          albumPeak:
              $checkedConvert('albumPeak', (v) => (v as num?)?.toDouble()),
          baseGain: $checkedConvert('baseGain', (v) => (v as num?)?.toDouble()),
          fallbackGain:
              $checkedConvert('fallbackGain', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
    );
