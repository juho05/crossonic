/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

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
