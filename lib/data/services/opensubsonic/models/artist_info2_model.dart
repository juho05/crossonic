import 'package:crossonic/data/services/opensubsonic/models/artistid3_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'artist_info2_model.g.dart';

@JsonSerializable()
class ArtistInfo2Model {
  final String? biography;
  final String? musicBrainzId;
  final String? lastFmUrl;
  final String? smallImageUrl;
  final String? mediumImageUrl;
  final String? largeImageUrl;
  final List<ArtistID3Model>? similarArtist;

  ArtistInfo2Model({
    required this.biography,
    required this.musicBrainzId,
    required this.lastFmUrl,
    required this.smallImageUrl,
    required this.mediumImageUrl,
    required this.largeImageUrl,
    required this.similarArtist,
  });

  factory ArtistInfo2Model.fromJson(Map<String, dynamic> json) =>
      _$ArtistInfo2ModelFromJson(json);
}
