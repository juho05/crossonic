import 'package:crossonic/repositories/api/models/models.dart';
import 'package:json_annotation/json_annotation.dart';

part 'contributor_model.g.dart';

@JsonSerializable()
class Contributor {
  final String role;
  final String? subRole;
  final ArtistID3 artist;

  Contributor({
    required this.role,
    required this.subRole,
    required this.artist,
  });

  factory Contributor.fromJson(Map<String, dynamic> json) =>
      _$ContributorFromJson(json);
}
