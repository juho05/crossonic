import 'package:crossonic/repositories/api/models/playlist_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'getplaylists_response.g.dart';

@JsonSerializable()
class GetPlaylistsResponse {
  final List<Playlist> playlist;

  GetPlaylistsResponse({
    required this.playlist,
  });

  factory GetPlaylistsResponse.fromJson(Map<String, dynamic> json) =>
      _$GetPlaylistsResponseFromJson(json);
}
