import 'package:crossonic/repositories/subsonic/models/models.dart';
import 'package:crossonic/repositories/subsonic/subsonic.dart';
import 'package:json_annotation/json_annotation.dart';

part 'getrandom_songs_response.g.dart';

@JsonSerializable()
class GetRandomSongsResponse {
  final List<Media>? song;

  GetRandomSongsResponse({
    required this.song,
  });

  factory GetRandomSongsResponse.fromJson(Map<String, dynamic> json) =>
      _$GetRandomSongsResponseFromJson(json);
}
