// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter

part of 'search3_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Search3Response _$Search3ResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'Search3Response',
      json,
      ($checkedConvert) {
        final val = Search3Response(
          artist: $checkedConvert(
              'artist',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => ArtistID3.fromJson(e as Map<String, dynamic>))
                  .toList()),
          album: $checkedConvert(
              'album',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => AlbumID3.fromJson(e as Map<String, dynamic>))
                  .toList()),
          song: $checkedConvert(
              'song',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => Media.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$Search3ResponseToJson(Search3Response instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('artist', instance.artist);
  writeNotNull('album', instance.album);
  writeNotNull('song', instance.song);
  return val;
}
