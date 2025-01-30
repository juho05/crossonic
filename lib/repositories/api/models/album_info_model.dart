import 'package:json_annotation/json_annotation.dart';

part 'album_info_model.g.dart';

@JsonSerializable()
class AlbumInfo {
  final String? notes;
  final String? musicBrainzId;
  final String? lastFmUrl;

  AlbumInfo({
    this.notes,
    this.musicBrainzId,
    this.lastFmUrl,
  });

  factory AlbumInfo.fromJson(Map<String, dynamic> json) =>
      _$AlbumInfoFromJson(json);
}
