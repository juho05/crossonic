import 'package:json_annotation/json_annotation.dart';

part 'scrobble.g.dart';

@JsonSerializable()
class Scrobble {
  final int timeUnixMS;
  final int durationMS;
  final String songID;

  Scrobble({
    required this.timeUnixMS,
    required this.durationMS,
    required this.songID,
  });

  factory Scrobble.fromJson(Map<String, dynamic> json) =>
      _$ScrobbleFromJson(json);

  Map<String, dynamic> toJson() => _$ScrobbleToJson(this);
}
