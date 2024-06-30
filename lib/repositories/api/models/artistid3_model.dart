import 'package:json_annotation/json_annotation.dart';

part 'artistid3_model.g.dart';

@JsonSerializable()
class ArtistID3 {
  final String id;
  final String name;
  final String? coverArt;
  final String? artistImageUrl;
  final int? albumCount;
  final DateTime? starred;
  final String? musicBrainzId;
  final String? sortName;
  final List<String>? roles;

  ArtistID3({
    required this.id,
    required this.name,
    required this.coverArt,
    required this.artistImageUrl,
    required this.albumCount,
    required this.starred,
    required this.musicBrainzId,
    required this.sortName,
    required this.roles,
  });

  factory ArtistID3.fromJson(Map<String, dynamic> json) =>
      _$ArtistID3FromJson(json);

  Map<String, dynamic> toJson() => _$ArtistID3ToJson(this);
}
