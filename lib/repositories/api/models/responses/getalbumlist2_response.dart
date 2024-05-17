import 'package:crossonic/repositories/api/models/albumid3_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'getalbumlist2_response.g.dart';

@JsonSerializable()
class AlbumList2Response {
  final List<AlbumID3>? album;

  AlbumList2Response({
    this.album,
  });

  factory AlbumList2Response.fromJson(Map<String, dynamic> json) =>
      _$AlbumList2ResponseFromJson(json);
}
