// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter

part of 'getrandom_songs_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetRandomSongsResponse _$GetRandomSongsResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'GetRandomSongsResponse',
      json,
      ($checkedConvert) {
        final val = GetRandomSongsResponse(
          song: $checkedConvert(
              'song',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => Media.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );
