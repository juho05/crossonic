import 'package:crossonic/data/services/opensubsonic/models/albumid3_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'appears_on_model.g.dart';

@JsonSerializable()
class AppearsOnModel {
  final List<AlbumID3Model>? album;
  AppearsOnModel({
    required this.album,
  });

  factory AppearsOnModel.fromJson(Map<String, dynamic> json) =>
      _$AppearsOnModelFromJson(json);

  Map<String, dynamic> toJson() => _$AppearsOnModelToJson(this);
}
