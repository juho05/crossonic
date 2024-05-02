// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter

part of 'media_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Media _$MediaFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Media',
      json,
      ($checkedConvert) {
        final val = Media(
          id: $checkedConvert('id', (v) => v as String),
          parent: $checkedConvert('parent', (v) => v as String?),
          isDir: $checkedConvert('isDir', (v) => v as bool),
          title: $checkedConvert('title', (v) => v as String),
          album: $checkedConvert('album', (v) => v as String?),
          artist: $checkedConvert('artist', (v) => v as String?),
          track: $checkedConvert('track', (v) => (v as num?)?.toInt()),
          year: $checkedConvert('year', (v) => (v as num?)?.toInt()),
          genre: $checkedConvert('genre', (v) => v as String?),
          coverArt: $checkedConvert('coverArt', (v) => v as String?),
          size: $checkedConvert('size', (v) => (v as num?)?.toInt()),
          contentType: $checkedConvert('contentType', (v) => v as String?),
          suffix: $checkedConvert('suffix', (v) => v as String?),
          transcodedContentType:
              $checkedConvert('transcodedContentType', (v) => v as String?),
          transcodedSuffix:
              $checkedConvert('transcodedSuffix', (v) => v as String?),
          duration: $checkedConvert('duration', (v) => (v as num?)?.toInt()),
          bitRate: $checkedConvert('bitRate', (v) => (v as num?)?.toInt()),
          bitDepth: $checkedConvert('bitDepth', (v) => (v as num?)?.toInt()),
          samplingRate:
              $checkedConvert('samplingRate', (v) => (v as num?)?.toInt()),
          channelCount:
              $checkedConvert('channelCount', (v) => (v as num?)?.toInt()),
          path: $checkedConvert('path', (v) => v as String?),
          isVideo: $checkedConvert('isVideo', (v) => v as bool?),
          userRating:
              $checkedConvert('userRating', (v) => (v as num?)?.toInt()),
          averageRating:
              $checkedConvert('averageRating', (v) => (v as num?)?.toDouble()),
          playCount: $checkedConvert('playCount', (v) => (v as num?)?.toInt()),
          discNumber:
              $checkedConvert('discNumber', (v) => (v as num?)?.toInt()),
          created: $checkedConvert(
              'created', (v) => v == null ? null : DateTime.parse(v as String)),
          starred: $checkedConvert(
              'starred', (v) => v == null ? null : DateTime.parse(v as String)),
          albumId: $checkedConvert('albumId', (v) => v as String?),
          artistId: $checkedConvert('artistId', (v) => v as String?),
          type: $checkedConvert('type', (v) => v as String?),
          mediaType: $checkedConvert('mediaType', (v) => v as String?),
          bookmarkPosition:
              $checkedConvert('bookmarkPosition', (v) => (v as num?)?.toInt()),
          originalWidth:
              $checkedConvert('originalWidth', (v) => (v as num?)?.toInt()),
          originalHeight:
              $checkedConvert('originalHeight', (v) => (v as num?)?.toInt()),
          played: $checkedConvert(
              'played', (v) => v == null ? null : DateTime.parse(v as String)),
          bpm: $checkedConvert('bpm', (v) => (v as num?)?.toInt()),
          comment: $checkedConvert('comment', (v) => v as String?),
          sortName: $checkedConvert('sortName', (v) => v as String?),
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
          albumArtists: $checkedConvert(
              'albumArtists',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => ArtistID3.fromJson(e as Map<String, dynamic>))
                  .toList()),
          displayAlbumArtist:
              $checkedConvert('displayAlbumArtist', (v) => v as String?),
          contributors: $checkedConvert(
              'contributors',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => Contributor.fromJson(e as Map<String, dynamic>))
                  .toList()),
          displayContributor:
              $checkedConvert('displayContributor', (v) => v as String?),
          moods: $checkedConvert('moods',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          replayGain: $checkedConvert(
              'replayGain',
              (v) => v == null
                  ? null
                  : ReplayGain.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$MediaToJson(Media instance) {
  final val = <String, dynamic>{
    'id': instance.id,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('parent', instance.parent);
  val['isDir'] = instance.isDir;
  val['title'] = instance.title;
  writeNotNull('album', instance.album);
  writeNotNull('artist', instance.artist);
  writeNotNull('track', instance.track);
  writeNotNull('year', instance.year);
  writeNotNull('genre', instance.genre);
  writeNotNull('coverArt', instance.coverArt);
  writeNotNull('size', instance.size);
  writeNotNull('contentType', instance.contentType);
  writeNotNull('suffix', instance.suffix);
  writeNotNull('transcodedContentType', instance.transcodedContentType);
  writeNotNull('transcodedSuffix', instance.transcodedSuffix);
  writeNotNull('duration', instance.duration);
  writeNotNull('bitRate', instance.bitRate);
  writeNotNull('bitDepth', instance.bitDepth);
  writeNotNull('samplingRate', instance.samplingRate);
  writeNotNull('channelCount', instance.channelCount);
  writeNotNull('path', instance.path);
  writeNotNull('isVideo', instance.isVideo);
  writeNotNull('userRating', instance.userRating);
  writeNotNull('averageRating', instance.averageRating);
  writeNotNull('playCount', instance.playCount);
  writeNotNull('discNumber', instance.discNumber);
  writeNotNull('created', instance.created?.toIso8601String());
  writeNotNull('starred', instance.starred?.toIso8601String());
  writeNotNull('albumId', instance.albumId);
  writeNotNull('artistId', instance.artistId);
  writeNotNull('type', instance.type);
  writeNotNull('mediaType', instance.mediaType);
  writeNotNull('bookmarkPosition', instance.bookmarkPosition);
  writeNotNull('originalWidth', instance.originalWidth);
  writeNotNull('originalHeight', instance.originalHeight);
  writeNotNull('played', instance.played?.toIso8601String());
  writeNotNull('bpm', instance.bpm);
  writeNotNull('comment', instance.comment);
  writeNotNull('sortName', instance.sortName);
  writeNotNull('musicBrainzId', instance.musicBrainzId);
  writeNotNull('genres', instance.genres);
  writeNotNull('artists', instance.artists);
  writeNotNull('displayArtist', instance.displayArtist);
  writeNotNull('albumArtists', instance.albumArtists);
  writeNotNull('displayAlbumArtist', instance.displayAlbumArtist);
  writeNotNull('contributors', instance.contributors);
  writeNotNull('displayContributor', instance.displayContributor);
  writeNotNull('moods', instance.moods);
  writeNotNull('replayGain', instance.replayGain);
  return val;
}
