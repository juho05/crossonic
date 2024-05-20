// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter

part of 'scrobble.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Scrobble _$ScrobbleFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Scrobble',
      json,
      ($checkedConvert) {
        final val = Scrobble(
          timeUnixMS: $checkedConvert('timeUnixMS', (v) => (v as num).toInt()),
          durationMS: $checkedConvert('durationMS', (v) => (v as num).toInt()),
          songID: $checkedConvert('songID', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$ScrobbleToJson(Scrobble instance) => <String, dynamic>{
      'timeUnixMS': instance.timeUnixMS,
      'durationMS': instance.durationMS,
      'songID': instance.songID,
    };
