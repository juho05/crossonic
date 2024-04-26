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

Map<String, dynamic> _$ReplayGainToJson(ReplayGain instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('trackGain', instance.trackGain);
  writeNotNull('albumGain', instance.albumGain);
  writeNotNull('trackPeak', instance.trackPeak);
  writeNotNull('albumPeak', instance.albumPeak);
  writeNotNull('baseGain', instance.baseGain);
  writeNotNull('fallbackGain', instance.fallbackGain);
  return val;
}
