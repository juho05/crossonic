import 'package:json_annotation/json_annotation.dart';

part 'item_genre_model.g.dart';

@JsonSerializable()
class ItemGenre {
  final String name;
  ItemGenre({
    required this.name,
  });

  factory ItemGenre.fromJson(Map<String, dynamic> json) =>
      _$ItemGenreFromJson(json);
}
