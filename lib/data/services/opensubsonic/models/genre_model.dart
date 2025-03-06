import 'package:json_annotation/json_annotation.dart';

part 'genre_model.g.dart';

@JsonSerializable()
class GenreModel {
  final String value;
  final int albumCount;
  final int songCount;

  GenreModel({
    required this.value,
    required this.albumCount,
    required this.songCount,
  });

  factory GenreModel.fromJson(Map<String, dynamic> json) =>
      _$GenreModelFromJson(json);
}
