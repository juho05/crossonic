import 'package:crossonic/repositories/subsonic/models/models.dart';
import 'package:crossonic/repositories/subsonic/subsonic.dart';
import 'package:json_annotation/json_annotation.dart';

part 'get_random_songs_response.g.dart';

@JsonSerializable()
class GetRandomSongs {
  final List<Child> song;

  GetRandomSongs({
    required this.song,
  });

  factory GetRandomSongs.fromJson(Map<String, dynamic> json) =>
      _$GetRandomSongsFromJson(json);
}
