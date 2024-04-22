// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter

part of 'get_random_songs_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetRandomSongs _$GetRandomSongsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'GetRandomSongs',
      json,
      ($checkedConvert) {
        final val = GetRandomSongs(
          song: $checkedConvert(
              'song',
              (v) => (v as List<dynamic>)
                  .map((e) => Media.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );
