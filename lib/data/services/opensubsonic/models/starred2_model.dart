import 'package:crossonic/data/services/opensubsonic/models/child_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'starred2_model.g.dart';

@JsonSerializable()
class Starred2Model {
  // TODO
  // final List<ArtistID3Model> artist;
  // final List<AlbumID3Model> album;
  final List<ChildModel> song;

  Starred2Model({required this.song});

  factory Starred2Model.fromJson(Map<String, dynamic> json) =>
      _$Starred2ModelFromJson(json);
}
