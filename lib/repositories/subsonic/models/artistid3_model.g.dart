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
          albumCount: $checkedConvert('albumCount', (v) => v as int?),
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
