import 'package:crossonic/data/repositories/subsonic/models/date.dart';
import 'package:crossonic/data/services/opensubsonic/models/child_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'song.g.dart';

@JsonSerializable()
class Song {
  final String id;
  final String coverId;
  final String title;
  final String displayArtist;
  final Iterable<({String id, String name})> artists;
  final ({String id, String name})? album;
  final Iterable<String> genres;
  final Duration? duration;
  final int? bpm;
  final int? trackNr;
  final int? discNr;
  final double? trackGain;
  final double? albumGain;
  final double? fallbackGain;
  final Date? originalDate;
  final Date? releaseDate;

  Song({
    required this.id,
    required this.coverId,
    required this.title,
    required this.displayArtist,
    required this.artists,
    required this.album,
    required this.genres,
    required this.duration,
    required this.bpm,
    required this.trackNr,
    required this.discNr,
    required this.trackGain,
    required this.albumGain,
    required this.fallbackGain,
    required this.originalDate,
    required this.releaseDate,
  });

  factory Song.fromChildModel(ChildModel child) {
    Date? originalDate;
    if (child.originalReleaseDate != null &&
        child.originalReleaseDate!.year != null) {
      originalDate = Date.fromItemDateModel(child.originalReleaseDate!);
    } else if (child.year != null) {
      originalDate = Date(year: child.year!, month: null, day: null);
    }

    Date? releaseDate;
    if (child.releaseDate != null && child.releaseDate!.year != null) {
      releaseDate = Date.fromItemDateModel(child.releaseDate!);
    } else if (child.year != null) {
      releaseDate = Date(year: child.year!, month: null, day: null);
    }

    if (releaseDate != null) {
      if (originalDate != null) {
        if (originalDate > releaseDate) {
          releaseDate = null;
        }
      } else {
        originalDate = releaseDate;
      }
    }

    if (originalDate == releaseDate) {
      releaseDate = null;
    }

    return Song(
      id: child.id,
      coverId: child.coverArt ?? child.id,
      title: child.title,
      displayArtist: child.displayArtist ??
          child.artists?.map((a) => a.name).join(", ") ??
          child.artist ??
          child.displayAlbumArtist ??
          child.albumArtists?.map((a) => a.name).join(", ") ??
          "Unknown artist",
      artists: child.artists ??
          child.albumArtists ??
          (child.artistId == null && child.artist == null
              ? [(id: child.artistId!, name: child.artist!)]
              : null) ??
          [],
      album: child.albumId != null && child.album != null
          ? (id: child.albumId!, name: child.album!)
          : null,
      genres: child.genres != null
          ? child.genres!.map((g) => g.name)
          : (child.genre != null ? [child.genre!] : []),
      duration:
          child.duration != null ? Duration(seconds: child.duration!) : null,
      releaseDate: releaseDate,
      originalDate: originalDate,
      bpm: child.bpm,
      trackNr: child.track,
      discNr: child.discNumber,
      trackGain: child.replayGain?.trackGain,
      albumGain: child.replayGain?.albumGain,
      fallbackGain: child.replayGain?.fallbackGain,
    );
  }

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);

  Map<String, dynamic> toJson() => _$SongToJson(this);
}
