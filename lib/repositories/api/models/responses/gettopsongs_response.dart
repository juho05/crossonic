import 'package:crossonic/repositories/api/models/models.dart';
import 'package:crossonic/repositories/api/api.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gettopsongs_response.g.dart';

@JsonSerializable()
class GetTopSongsResponse {
  final List<Media>? song;

  GetTopSongsResponse({
    required this.song,
  });

  factory GetTopSongsResponse.fromJson(Map<String, dynamic> json) =>
      _$GetTopSongsResponseFromJson(json);
}
