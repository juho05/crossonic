import 'package:json_annotation/json_annotation.dart';

part 'contributor_model.g.dart';

@JsonSerializable()
class ContributorModel {
  final String role;
  final String? subRole;
  final ({String id, String name}) artist;

  ContributorModel({
    required this.role,
    required this.subRole,
    required this.artist,
  });

  factory ContributorModel.fromJson(Map<String, dynamic> json) =>
      _$ContributorModelFromJson(json);

  Map<String, dynamic> toJson() => _$ContributorModelToJson(this);
}
