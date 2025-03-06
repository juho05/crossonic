import 'package:json_annotation/json_annotation.dart';

part 'lyrics_model.g.dart';

@JsonSerializable()
class LyricsModel {
  final String value;
  final String? artist;
  final String? title;

  LyricsModel({
    required this.artist,
    required this.title,
    required this.value,
  });

  factory LyricsModel.fromJson(Map<String, dynamic> json) =>
      _$LyricsModelFromJson(json);
}
