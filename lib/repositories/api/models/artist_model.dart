import 'package:crossonic/repositories/api/models/albumid3_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'artist_model.g.dart';

@JsonSerializable()
class Artist {
  final String id;
  final String name;
  final String? coverArt;
  final String? artistImageUrl;
  final int? albumCount;
  final DateTime? starred;
  final int? userRating;
  final double? averageRating;
  final List<AlbumID3>? album;

  Artist({
    required this.id,
    required this.name,
    required this.coverArt,
    required this.albumCount,
    required this.starred,
    required this.album,
    required this.artistImageUrl,
    required this.averageRating,
    required this.userRating,
  });

  factory Artist.fromJson(Map<String, dynamic> json) => _$ArtistFromJson(json);
}
