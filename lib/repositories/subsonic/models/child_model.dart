import 'package:crossonic/repositories/subsonic/models/models.dart';
import 'package:json_annotation/json_annotation.dart';

part 'child_model.g.dart';

@JsonSerializable()
class Child {
  final String id;
  final String? parent;
  final bool isDir;
  final String title;
  final String? album;
  final String? artist;
  final int? track;
  final int? year;
  final String? genre;
  final String? coverArt;
  final int? size;
  final String? contentType;
  final String? suffix;
  final String? transcodedContentType;
  final String? transcodedSuffix;
  final int? duration;
  final int? bitRate;
  final int? bitDepth;
  final int? samplingRate;
  final int? channelCount;
  final String? path;
  final bool? isVideo;
  final int? userRating;
  final double? averageRating;
  final int? playCount;
  final int? discNumber;
  final DateTime? created;
  final DateTime? starred;
  final String? albumId;
  final String? artistId;
  final String? type;
  final String? mediaType;
  final int? bookmarkPosition;
  final int? originalWidth;
  final int? originalHeight;
  final DateTime? played;
  final int? bpm;
  final String? comment;
  final String? sortName;
  final String? musicBrainzId;
  final List<ItemGenre>? genres;
  final List<ArtistID3>? artists;
  final String? displayArtist;
  final List<ArtistID3>? albumArtists;
  final String? displayAlbumArtist;
  final List<Contributor>? contributors;
  final String? displayContributor;
  final List<String>? moods;
  final ReplayGain? replayGain;

  Child({
    required this.id,
    required this.parent,
    required this.isDir,
    required this.title,
    required this.album,
    required this.artist,
    required this.track,
    required this.year,
    required this.genre,
    required this.coverArt,
    required this.size,
    required this.contentType,
    required this.suffix,
    required this.transcodedContentType,
    required this.transcodedSuffix,
    required this.duration,
    required this.bitRate,
    required this.bitDepth,
    required this.samplingRate,
    required this.channelCount,
    required this.path,
    required this.isVideo,
    required this.userRating,
    required this.averageRating,
    required this.playCount,
    required this.discNumber,
    required this.created,
    required this.starred,
    required this.albumId,
    required this.artistId,
    required this.type,
    required this.mediaType,
    required this.bookmarkPosition,
    required this.originalWidth,
    required this.originalHeight,
    required this.played,
    required this.bpm,
    required this.comment,
    required this.sortName,
    required this.musicBrainzId,
    required this.genres,
    required this.artists,
    required this.displayArtist,
    required this.albumArtists,
    required this.displayAlbumArtist,
    required this.contributors,
    required this.displayContributor,
    required this.moods,
    required this.replayGain,
  });

  factory Child.fromJson(Map<String, dynamic> json) => _$ChildFromJson(json);
}
