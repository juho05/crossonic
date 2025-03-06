import 'package:crossonic/data/services/opensubsonic/models/genre_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'genres_model.g.dart';

@JsonSerializable()
class GenresModel {
  final List<GenreModel>? genre;

  GenresModel({
    required this.genre,
  });

  factory GenresModel.fromJson(Map<String, dynamic> json) =>
      _$GenresModelFromJson(json);

  Map<String, dynamic> toJson() => _$GenresModelToJson(this);
}
