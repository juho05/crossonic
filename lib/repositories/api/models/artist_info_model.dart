import 'package:json_annotation/json_annotation.dart';

part 'artist_info_model.g.dart';

@JsonSerializable()
class ArtistInfo2 {
  final String? biography;
  final String? musicBrainzId;
  final String? lastFmUrl;

  ArtistInfo2({
    this.biography,
    this.musicBrainzId,
    this.lastFmUrl,
  });

  factory ArtistInfo2.fromJson(Map<String, dynamic> json) =>
      _$ArtistInfo2FromJson(json);
}
