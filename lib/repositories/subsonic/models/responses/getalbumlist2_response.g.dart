// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter

part of 'getalbumlist2_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlbumList2Response _$AlbumList2ResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AlbumList2Response',
      json,
      ($checkedConvert) {
        final val = AlbumList2Response(
          album: $checkedConvert(
              'album',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => AlbumID3.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );
