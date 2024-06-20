import 'package:crossonic/repositories/api/models/models.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'playlist_model.g.dart';

@JsonSerializable()
class Playlist extends Equatable {
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
  final List<Media>? entry;

  const Playlist({
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

  factory Playlist.fromJson(Map<String, dynamic> json) =>
      _$PlaylistFromJson(json);

  @override
  List<Object?> get props => [
        id,
        name,
        comment,
        owner,
        public,
        songCount,
        duration,
        created,
        changed,
        coverArt,
        allowedUser,
        entry
      ];
}
