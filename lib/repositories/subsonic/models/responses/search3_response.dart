import 'package:crossonic/repositories/subsonic/models/albumid3_model.dart';
import 'package:crossonic/repositories/subsonic/models/models.dart';
import 'package:crossonic/repositories/subsonic/subsonic.dart';
import 'package:json_annotation/json_annotation.dart';

part 'search3_response.g.dart';

@JsonSerializable()
class Search3Response {
  final List<ArtistID3>? artist;
  final List<AlbumID3>? album;
  final List<Media>? song;

  Search3Response({
    this.artist,
    this.album,
    this.song,
  });

  factory Search3Response.fromJson(Map<String, dynamic> json) =>
      _$Search3ResponseFromJson(json);
}
