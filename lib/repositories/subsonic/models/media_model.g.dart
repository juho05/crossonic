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
          track: $checkedConvert('track', (v) => v as int?),
          year: $checkedConvert('year', (v) => v as int?),
          genre: $checkedConvert('genre', (v) => v as String?),
          coverArt: $checkedConvert('coverArt', (v) => v as String?),
          size: $checkedConvert('size', (v) => v as int?),
          contentType: $checkedConvert('contentType', (v) => v as String?),
          suffix: $checkedConvert('suffix', (v) => v as String?),
          transcodedContentType:
              $checkedConvert('transcodedContentType', (v) => v as String?),
          transcodedSuffix:
              $checkedConvert('transcodedSuffix', (v) => v as String?),
          duration: $checkedConvert('duration', (v) => v as int?),
          bitRate: $checkedConvert('bitRate', (v) => v as int?),
          bitDepth: $checkedConvert('bitDepth', (v) => v as int?),
          samplingRate: $checkedConvert('samplingRate', (v) => v as int?),
          channelCount: $checkedConvert('channelCount', (v) => v as int?),
          path: $checkedConvert('path', (v) => v as String?),
          isVideo: $checkedConvert('isVideo', (v) => v as bool?),
          userRating: $checkedConvert('userRating', (v) => v as int?),
          averageRating:
              $checkedConvert('averageRating', (v) => (v as num?)?.toDouble()),
          playCount: $checkedConvert('playCount', (v) => v as int?),
          discNumber: $checkedConvert('discNumber', (v) => v as int?),
          created: $checkedConvert(
              'created', (v) => v == null ? null : DateTime.parse(v as String)),
          starred: $checkedConvert(
              'starred', (v) => v == null ? null : DateTime.parse(v as String)),
          albumId: $checkedConvert('albumId', (v) => v as String?),
          artistId: $checkedConvert('artistId', (v) => v as String?),
          type: $checkedConvert('type', (v) => v as String?),
          mediaType: $checkedConvert('mediaType', (v) => v as String?),
          bookmarkPosition:
              $checkedConvert('bookmarkPosition', (v) => v as int?),
          originalWidth: $checkedConvert('originalWidth', (v) => v as int?),
          originalHeight: $checkedConvert('originalHeight', (v) => v as int?),
          played: $checkedConvert(
              'played', (v) => v == null ? null : DateTime.parse(v as String)),
          bpm: $checkedConvert('bpm', (v) => v as int?),
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
