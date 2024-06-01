import 'package:json_annotation/json_annotation.dart';

part 'structured_lyrics_model.g.dart';

@JsonSerializable()
class StructuredLyrics {
  final String lang;
  final bool synced;
  final String? displayArtist;
  final String? displayTitle;
  final int? offset;
  final List<Line> line;

  StructuredLyrics({
    required this.lang,
    required this.synced,
    required this.displayArtist,
    required this.displayTitle,
    required this.offset,
    required this.line,
  });

  factory StructuredLyrics.fromJson(Map<String, dynamic> json) =>
      _$StructuredLyricsFromJson(json);
}

@JsonSerializable()
class Line {
  final int? start;
  final String value;

  Line({
    required this.start,
    required this.value,
  });

  factory Line.fromJson(Map<String, dynamic> json) => _$LineFromJson(json);
}
