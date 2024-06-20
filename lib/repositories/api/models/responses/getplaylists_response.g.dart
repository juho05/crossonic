// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter

part of 'getplaylists_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetPlaylistsResponse _$GetPlaylistsResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'GetPlaylistsResponse',
      json,
      ($checkedConvert) {
        final val = GetPlaylistsResponse(
          playlist: $checkedConvert(
              'playlist',
              (v) => (v as List<dynamic>)
                  .map((e) => Playlist.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$GetPlaylistsResponseToJson(
        GetPlaylistsResponse instance) =>
    <String, dynamic>{
      'playlist': instance.playlist,
    };
