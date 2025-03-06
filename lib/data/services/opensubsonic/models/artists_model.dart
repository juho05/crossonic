import 'package:crossonic/data/services/opensubsonic/models/indexid3_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'artists_model.g.dart';

@JsonSerializable()
class ArtistsModel {
  final String ignoredArticles;
  final List<IndexID3Model>? index;

  ArtistsModel({
    required this.ignoredArticles,
    required this.index,
  });

  factory ArtistsModel.fromJson(Map<String, dynamic> json) =>
      _$ArtistsModelFromJson(json);

  Map<String, dynamic> toJson() => _$ArtistsModelToJson(this);
}
