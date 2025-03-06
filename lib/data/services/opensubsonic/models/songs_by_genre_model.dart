import 'package:crossonic/data/services/opensubsonic/models/child_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'songs_by_genre_model.g.dart';

@JsonSerializable()
class SongsByGenreModel {
  final List<ChildModel>? song;

  SongsByGenreModel({required this.song});

  factory SongsByGenreModel.fromJson(Map<String, dynamic> json) =>
      _$SongsByGenreModelFromJson(json);
}
