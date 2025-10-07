import 'package:crossonic/data/services/opensubsonic/models/playlist_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'playlists_model.g.dart';

@JsonSerializable()
class PlaylistsModel {
  final List<PlaylistModel>? playlist;

  PlaylistsModel({required this.playlist});

  factory PlaylistsModel.fromJson(Map<String, dynamic> json) =>
      _$PlaylistsModelFromJson(json);

  Map<String, dynamic> toJson() => _$PlaylistsModelToJson(this);
}
