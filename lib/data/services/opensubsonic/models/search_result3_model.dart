import 'package:crossonic/data/services/opensubsonic/models/albumid3_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/artistid3_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/child_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'search_result3_model.g.dart';

@JsonSerializable()
class SearchResult3Model {
  final List<ChildModel>? song;
  final List<AlbumID3Model>? album;
  final List<ArtistID3Model>? artist;

  SearchResult3Model({
    required this.song,
    required this.album,
    required this.artist,
  });

  factory SearchResult3Model.fromJson(Map<String, dynamic> json) =>
      _$SearchResult3ModelFromJson(json);

  Map<String, dynamic> toJson() => _$SearchResult3ModelToJson(this);
}
