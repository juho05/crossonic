import 'package:crossonic/data/services/opensubsonic/models/child_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'songs_model.g.dart';

@JsonSerializable()
class SongsModel {
  final List<ChildModel>? song;

  SongsModel({required this.song});

  factory SongsModel.fromJson(Map<String, dynamic> json) =>
      _$SongsModelFromJson(json);

  Map<String, dynamic> toJson() => _$SongsModelToJson(this);
}
