import 'package:crossonic/data/repositories/subsonic/models/date.dart';
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

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);

  Map<String, dynamic> toJson() => _$SongToJson(this);
}
