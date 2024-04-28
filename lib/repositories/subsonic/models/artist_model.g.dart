// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter

part of 'artist_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Artist _$ArtistFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Artist',
      json,
      ($checkedConvert) {
        final val = Artist(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          coverArt: $checkedConvert('coverArt', (v) => v as String?),
          albumCount:
              $checkedConvert('albumCount', (v) => (v as num?)?.toInt()),
          starred: $checkedConvert(
              'starred', (v) => v == null ? null : DateTime.parse(v as String)),
          album: $checkedConvert(
              'album',
              (v) => (v as List<dynamic>)
                  .map((e) => AlbumID3.fromJson(e as Map<String, dynamic>))
                  .toList()),
          artistImageUrl:
              $checkedConvert('artistImageUrl', (v) => v as String?),
          averageRating:
              $checkedConvert('averageRating', (v) => (v as num?)?.toDouble()),
          userRating:
              $checkedConvert('userRating', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$ArtistToJson(Artist instance) {
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
  writeNotNull('userRating', instance.userRating);
  writeNotNull('averageRating', instance.averageRating);
  val['album'] = instance.album;
  return val;
}
