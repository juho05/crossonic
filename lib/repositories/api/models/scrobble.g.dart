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
          durationMS:
              $checkedConvert('durationMS', (v) => (v as num?)?.toInt()),
          songID: $checkedConvert('songID', (v) => v as String),
          songName: $checkedConvert('songName', (v) => v as String),
          songDuration:
              $checkedConvert('songDuration', (v) => (v as num?)?.toInt()),
          musicBrainzID: $checkedConvert('musicBrainzID', (v) => v as String?),
          albumID: $checkedConvert('albumID', (v) => v as String?),
          albumName: $checkedConvert('albumName', (v) => v as String?),
          artistID: $checkedConvert('artistID', (v) => v as String?),
          artistName: $checkedConvert('artistName', (v) => v as String?),
          update: $checkedConvert('update', (v) => v as bool? ?? false),
        );
        return val;
      },
    );

Map<String, dynamic> _$ScrobbleToJson(Scrobble instance) {
  final val = <String, dynamic>{
    'timeUnixMS': instance.timeUnixMS,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('durationMS', instance.durationMS);
  val['songID'] = instance.songID;
  val['songName'] = instance.songName;
  writeNotNull('songDuration', instance.songDuration);
  writeNotNull('musicBrainzID', instance.musicBrainzID);
  writeNotNull('albumID', instance.albumID);
  writeNotNull('albumName', instance.albumName);
  writeNotNull('artistID', instance.artistID);
  writeNotNull('artistName', instance.artistName);
  val['update'] = instance.update;
  return val;
}
