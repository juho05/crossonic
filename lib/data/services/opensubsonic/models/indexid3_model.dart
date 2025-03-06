import 'package:crossonic/data/services/opensubsonic/models/artistid3_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'indexid3_model.g.dart';

@JsonSerializable()
class IndexID3Model {
  final String name;
  final List<ArtistID3Model>? artist;

  IndexID3Model({
    required this.name,
    required this.artist,
  });

  factory IndexID3Model.fromJson(Map<String, dynamic> json) =>
      _$IndexID3ModelFromJson(json);

  Map<String, dynamic> toJson() => _$IndexID3ModelToJson(this);
}
