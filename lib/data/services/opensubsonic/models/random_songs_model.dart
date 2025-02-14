import 'package:crossonic/data/services/opensubsonic/models/child_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'random_songs_model.g.dart';

@JsonSerializable()
class RandomSongsModel {
  final List<ChildModel>? song;

  RandomSongsModel({required this.song});

  factory RandomSongsModel.fromJson(Map<String, dynamic> json) =>
      _$RandomSongsModelFromJson(json);
}
