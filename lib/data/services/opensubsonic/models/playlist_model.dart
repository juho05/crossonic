import 'package:crossonic/data/services/opensubsonic/models/child_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'playlist_model.g.dart';

@JsonSerializable()
class PlaylistModel {
  final String id;
  final String name;
  final String? comment;
  final String? owner;
  final bool? public;
  final int songCount;
  final int duration;
  final DateTime created;
  final DateTime changed;
  final String? coverArt;
  final List<String>? allowedUser;
  final List<ChildModel>? entry;

  PlaylistModel({
    required this.id,
    required this.name,
    required this.comment,
    required this.owner,
    required this.public,
    required this.songCount,
    required this.duration,
    required this.created,
    required this.changed,
    required this.coverArt,
    required this.allowedUser,
    required this.entry,
  });

  factory PlaylistModel.fromJson(Map<String, dynamic> json) =>
      _$PlaylistModelFromJson(json);

  Map<String, dynamic> toJson() => _$PlaylistModelToJson(this);
}
