import 'package:crossonic/data/services/opensubsonic/models/albumid3_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/datetime_converter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'artistid3_model.g.dart';

@JsonSerializable()
class ArtistID3Model {
  final String id;
  final String name;
  final String? coverArt;
  final String? artistImageUrl;
  final int? albumCount;
  @DateTimeConverter()
  final DateTime? starred;
  final String? musicBrainzId;
  final String? sortName;
  final List<String>? roles;
  final int? userRating;
  final double? averageRating;
  final List<AlbumID3Model>? album;

  ArtistID3Model({
    required this.id,
    required this.name,
    required this.coverArt,
    required this.artistImageUrl,
    required this.albumCount,
    required this.starred,
    required this.musicBrainzId,
    required this.sortName,
    required this.roles,
    required this.userRating,
    required this.averageRating,
    required this.album,
  });

  factory ArtistID3Model.fromJson(Map<String, dynamic> json) =>
      _$ArtistID3ModelFromJson(json);

  Map<String, dynamic> toJson() => _$ArtistID3ModelToJson(this);
}
