import 'package:crossonic/repositories/api/models/structured_lyrics_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'getlyricsbysongid_response.g.dart';

@JsonSerializable()
class GetLyricsBySongIdResponse {
  final List<StructuredLyrics>? structuredLyrics;

  GetLyricsBySongIdResponse({required this.structuredLyrics});

  factory GetLyricsBySongIdResponse.fromJson(Map<String, dynamic> json) =>
      _$GetLyricsBySongIdResponseFromJson(json);
}
