import 'package:crossonic/data/services/opensubsonic/models/albumid3_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'album_list2_model.g.dart';

@JsonSerializable()
class AlbumList2Model {
  final List<AlbumID3Model> album;
  AlbumList2Model({
    required this.album,
  });

  factory AlbumList2Model.fromJson(Map<String, dynamic> json) =>
      _$AlbumList2ModelFromJson(json);
}
