import 'package:json_annotation/json_annotation.dart';

part 'listenbrainz_config_model.g.dart';

@JsonSerializable()
class ListenBrainzConfigModel {
  final String? listenBrainzUsername;

  ListenBrainzConfigModel({
    required this.listenBrainzUsername,
  });

  factory ListenBrainzConfigModel.fromJson(Map<String, dynamic> json) =>
      _$ListenBrainzConfigModelFromJson(json);
}
