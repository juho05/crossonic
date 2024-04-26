import 'package:json_annotation/json_annotation.dart';

part 'scrobble.g.dart';

@JsonSerializable()
class Scrobble {
  final int timeUnixMS;
  final int? durationMS;

  final String songID;
  final String songName;
  final int? songDuration;
  final String? musicBrainzID;

  final String? albumID;
  final String? albumName;

  final String? artistID;
  final String? artistName;

  final String? scrobbleID;

  Scrobble({
    required this.timeUnixMS,
    this.durationMS,
    required this.songID,
    required this.songName,
    this.songDuration,
    this.musicBrainzID,
    this.albumID,
    this.albumName,
    this.artistID,
    this.artistName,
    this.scrobbleID,
  });

  factory Scrobble.fromJson(Map<String, dynamic> json) =>
      _$ScrobbleFromJson(json);

  Map<String, dynamic> toJson() => _$ScrobbleToJson(this);
}
