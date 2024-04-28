// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter

part of 'gettopsongs_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetTopSongsResponse _$GetTopSongsResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'GetTopSongsResponse',
      json,
      ($checkedConvert) {
        final val = GetTopSongsResponse(
          song: $checkedConvert(
              'song',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => Media.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$GetTopSongsResponseToJson(GetTopSongsResponse instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('song', instance.song);
  return val;
}
