import 'package:crossonic/data/services/opensubsonic/models/albumid3_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'album_versions_model.g.dart';

@JsonSerializable()
class AlbumVersionsModel {
  final List<AlbumID3Model> album;

  AlbumVersionsModel({
    required this.album,
  });

  factory AlbumVersionsModel.fromJson(Map<String, dynamic> json) =>
      _$AlbumVersionsModelFromJson(json);

  Map<String, dynamic> toJson() => _$AlbumVersionsModelToJson(this);
}
