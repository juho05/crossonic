/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:json_annotation/json_annotation.dart';

part 'music_folder_model.g.dart';

@JsonSerializable()
class MusicFolderModel {
  final int id;
  final String? name;

  MusicFolderModel({required this.id, required this.name});

  factory MusicFolderModel.fromJson(Map<String, dynamic> json) =>
      _$MusicFolderModelFromJson(json);

  Map<String, dynamic> toJson() => _$MusicFolderModelToJson(this);
}

@JsonSerializable()
class MusicFoldersModel {
  final List<MusicFolderModel> musicFolder;

  MusicFoldersModel({required this.musicFolder});

  factory MusicFoldersModel.fromJson(Map<String, dynamic> json) =>
      _$MusicFoldersModelFromJson(json);

  Map<String, dynamic> toJson() => _$MusicFoldersModelToJson(this);
}
