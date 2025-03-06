import 'package:crossonic/data/services/opensubsonic/models/structured_lyrics_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lyrics_list_model.g.dart';

@JsonSerializable()
class LyricsListModel {
  final List<StructuredLyricsModel> structuredLyrics;

  LyricsListModel({
    required this.structuredLyrics,
  });

  factory LyricsListModel.fromJson(Map<String, dynamic> json) =>
      _$LyricsListModelFromJson(json);
}
