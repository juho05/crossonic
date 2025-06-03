import 'package:json_annotation/json_annotation.dart';

part 'tag.g.dart';

@JsonSerializable()
class GitHubTag {
  final String name;
  final ({String sha, String url}) commit;
  @JsonKey(name: "zipball_url")
  final String zipballUrl;
  @JsonKey(name: "tarball_url")
  final String tarballUrl;
  @JsonKey(name: "node_id")
  final String nodeId;

  GitHubTag({
    required this.name,
    required this.commit,
    required this.zipballUrl,
    required this.tarballUrl,
    required this.nodeId,
  });

  factory GitHubTag.fromJson(Map<String, dynamic> json) =>
      _$GitHubTagFromJson(json);

  Map<String, dynamic> toJson() => _$GitHubTagToJson(this);
}
