import 'package:json_annotation/json_annotation.dart';

part 'album_info_model.g.dart';

@JsonSerializable()
class AlbumInfoModel {
  final String? notes;
  final String? musicBrainzId;
  final String? lastFmUrl;
  final String? smallImageUrl;
  final String? mediumImageUrl;
  final String? largeImageUrl;

  AlbumInfoModel({
    required this.notes,
    required this.musicBrainzId,
    required this.lastFmUrl,
    required this.smallImageUrl,
    required this.mediumImageUrl,
    required this.largeImageUrl,
  });

  factory AlbumInfoModel.fromJson(Map<String, dynamic> json) =>
      _$AlbumInfoModelFromJson(json);
}
