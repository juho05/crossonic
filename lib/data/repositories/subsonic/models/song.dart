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
  final int? year;
  final int? trackNr;
  final int? discNr;
  final double? trackGain;
  final double? albumGain;
  final double? fallbackGain;

  Song({
    required this.id,
    required this.coverId,
    required this.title,
    required this.displayArtist,
    required this.artists,
    required this.album,
    required this.genres,
    required this.duration,
    required this.year,
    required this.trackNr,
    required this.discNr,
    required this.trackGain,
    required this.albumGain,
    required this.fallbackGain,
  });

  factory Song.fromChildModel(ChildModel child) {
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
      year: child.year,
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
