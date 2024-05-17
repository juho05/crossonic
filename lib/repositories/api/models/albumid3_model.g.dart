// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter

part of 'albumid3_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlbumID3 _$AlbumID3FromJson(Map<String, dynamic> json) => $checkedCreate(
      'AlbumID3',
      json,
      ($checkedConvert) {
        final val = AlbumID3(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          artist: $checkedConvert('artist', (v) => v as String?),
          artistId: $checkedConvert('artistId', (v) => v as String?),
          coverArt: $checkedConvert('coverArt', (v) => v as String?),
          songCount: $checkedConvert('songCount', (v) => (v as num).toInt()),
          duration: $checkedConvert('duration', (v) => (v as num).toInt()),
          playCount: $checkedConvert('playCount', (v) => (v as num?)?.toInt()),
          created:
              $checkedConvert('created', (v) => DateTime.parse(v as String)),
          starred: $checkedConvert(
              'starred', (v) => v == null ? null : DateTime.parse(v as String)),
          year: $checkedConvert('year', (v) => (v as num?)?.toInt()),
          genre: $checkedConvert('genre', (v) => v as String?),
          played: $checkedConvert(
              'played', (v) => v == null ? null : DateTime.parse(v as String)),
          userRating:
              $checkedConvert('userRating', (v) => (v as num?)?.toInt()),
          recordLabels: $checkedConvert(
              'recordLabels',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => RecordLabel.fromJson(e as Map<String, dynamic>))
                  .toList()),
          musicBrainzId: $checkedConvert('musicBrainzId', (v) => v as String?),
          genres: $checkedConvert(
              'genres',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => ItemGenre.fromJson(e as Map<String, dynamic>))
                  .toList()),
          artists: $checkedConvert(
              'artists',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => ArtistID3.fromJson(e as Map<String, dynamic>))
                  .toList()),
          displayArtist: $checkedConvert('displayArtist', (v) => v as String?),
          releaseTypes: $checkedConvert('releaseTypes',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          moods: $checkedConvert('moods',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          sortName: $checkedConvert('sortName', (v) => v as String?),
          originalReleaseDate: $checkedConvert(
              'originalReleaseDate',
              (v) => v == null
                  ? null
                  : ItemDate.fromJson(v as Map<String, dynamic>)),
          releaseDate: $checkedConvert(
              'releaseDate',
              (v) => v == null
                  ? null
                  : ItemDate.fromJson(v as Map<String, dynamic>)),
          isCompilation: $checkedConvert('isCompilation', (v) => v as bool?),
          discTitles: $checkedConvert(
              'discTitles',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => DiscTitle.fromJson(e as Map<String, dynamic>))
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

Map<String, dynamic> _$AlbumID3ToJson(AlbumID3 instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'name': instance.name,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('artist', instance.artist);
  writeNotNull('artistId', instance.artistId);
  writeNotNull('coverArt', instance.coverArt);
  val['songCount'] = instance.songCount;
  val['duration'] = instance.duration;
  writeNotNull('playCount', instance.playCount);
  val['created'] = instance.created.toIso8601String();
  writeNotNull('starred', instance.starred?.toIso8601String());
  writeNotNull('year', instance.year);
  writeNotNull('genre', instance.genre);
  writeNotNull('played', instance.played?.toIso8601String());
  writeNotNull('userRating', instance.userRating);
  writeNotNull('recordLabels', instance.recordLabels);
  writeNotNull('musicBrainzId', instance.musicBrainzId);
  writeNotNull('genres', instance.genres);
  writeNotNull('artists', instance.artists);
  writeNotNull('displayArtist', instance.displayArtist);
  writeNotNull('releaseTypes', instance.releaseTypes);
  writeNotNull('moods', instance.moods);
  writeNotNull('sortName', instance.sortName);
  writeNotNull('originalReleaseDate', instance.originalReleaseDate);
  writeNotNull('releaseDate', instance.releaseDate);
  writeNotNull('isCompilation', instance.isCompilation);
  writeNotNull('discTitles', instance.discTitles);
  writeNotNull('song', instance.song);
  return val;
}
