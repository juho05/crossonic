import 'package:crossonic/data/services/opensubsonic/models/albumid3_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/artistid3_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/child_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'starred2_model.g.dart';

@JsonSerializable()
class Starred2Model {
  final List<ArtistID3Model>? artist;
  final List<AlbumID3Model>? album;
  final List<ChildModel>? song;

  Starred2Model({
    required this.song,
    required this.album,
    required this.artist,
  });

  factory Starred2Model.fromJson(Map<String, dynamic> json) =>
      _$Starred2ModelFromJson(json);

  Map<String, dynamic> toJson() => _$Starred2ModelToJson(this);
}
