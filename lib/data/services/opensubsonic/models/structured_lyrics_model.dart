import 'package:json_annotation/json_annotation.dart';

part 'structured_lyrics_model.g.dart';

typedef StructuredLyricsLine = ({
  String value,
  double? start,
});

@JsonSerializable()
class StructuredLyricsModel {
  final String lang;
  final bool synced;
  final List<StructuredLyricsLine> line;
  final String? displayArtist;
  final String? displayTitle;
  final double? offset;

  StructuredLyricsModel({
    required this.lang,
    required this.synced,
    required this.line,
    required this.displayArtist,
    required this.displayTitle,
    required this.offset,
  });

  factory StructuredLyricsModel.fromJson(Map<String, dynamic> json) =>
      _$StructuredLyricsModelFromJson(json);
}
