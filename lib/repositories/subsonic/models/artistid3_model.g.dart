// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter

part of 'artistid3_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArtistID3 _$ArtistID3FromJson(Map<String, dynamic> json) => $checkedCreate(
      'ArtistID3',
      json,
      ($checkedConvert) {
        final val = ArtistID3(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          coverArt: $checkedConvert('coverArt', (v) => v as String?),
          artistImageUrl:
              $checkedConvert('artistImageUrl', (v) => v as String?),
          albumCount:
              $checkedConvert('albumCount', (v) => (v as num?)?.toInt()),
          starred: $checkedConvert(
              'starred', (v) => v == null ? null : DateTime.parse(v as String)),
          musicBrainzId: $checkedConvert('musicBrainzId', (v) => v as String?),
          sortName: $checkedConvert('sortName', (v) => v as String?),
          roles: $checkedConvert('roles',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$ArtistID3ToJson(ArtistID3 instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'name': instance.name,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('coverArt', instance.coverArt);
  writeNotNull('artistImageUrl', instance.artistImageUrl);
  writeNotNull('albumCount', instance.albumCount);
  writeNotNull('starred', instance.starred?.toIso8601String());
  writeNotNull('musicBrainzId', instance.musicBrainzId);
  writeNotNull('sortName', instance.sortName);
  writeNotNull('roles', instance.roles);
  return val;
}
