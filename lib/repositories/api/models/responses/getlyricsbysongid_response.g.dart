// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter

part of 'getlyricsbysongid_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetLyricsBySongIdResponse _$GetLyricsBySongIdResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'GetLyricsBySongIdResponse',
      json,
      ($checkedConvert) {
        final val = GetLyricsBySongIdResponse(
          structuredLyrics: $checkedConvert(
              'structuredLyrics',
              (v) => (v as List<dynamic>?)
                  ?.map((e) =>
                      StructuredLyrics.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$GetLyricsBySongIdResponseToJson(
    GetLyricsBySongIdResponse instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('structuredLyrics', instance.structuredLyrics);
  return val;
}
