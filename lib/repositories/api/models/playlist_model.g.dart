// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter

part of 'playlist_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Playlist _$PlaylistFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Playlist',
      json,
      ($checkedConvert) {
        final val = Playlist(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          comment: $checkedConvert('comment', (v) => v as String?),
          owner: $checkedConvert('owner', (v) => v as String?),
          public: $checkedConvert('public', (v) => v as bool?),
          songCount: $checkedConvert('songCount', (v) => (v as num).toInt()),
          duration: $checkedConvert('duration', (v) => (v as num).toInt()),
          created:
              $checkedConvert('created', (v) => DateTime.parse(v as String)),
          changed:
              $checkedConvert('changed', (v) => DateTime.parse(v as String)),
          coverArt: $checkedConvert('coverArt', (v) => v as String?),
          allowedUser: $checkedConvert('allowedUser',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          entry: $checkedConvert(
              'entry',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => Media.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$PlaylistToJson(Playlist instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'name': instance.name,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('comment', instance.comment);
  writeNotNull('owner', instance.owner);
  writeNotNull('public', instance.public);
  val['songCount'] = instance.songCount;
  val['duration'] = instance.duration;
  val['created'] = instance.created.toIso8601String();
  val['changed'] = instance.changed.toIso8601String();
  writeNotNull('coverArt', instance.coverArt);
  writeNotNull('allowedUser', instance.allowedUser);
  writeNotNull('entry', instance.entry);
  return val;
}
