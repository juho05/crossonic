import 'package:json_annotation/json_annotation.dart';

part 'listenbrainz_config_model.g.dart';

@JsonSerializable()
class ListenBrainzConfigModel {
  final String? listenBrainzUsername;
  final bool? scrobble;
  final bool? syncFeedback;

  ListenBrainzConfigModel({
    required this.listenBrainzUsername,
    required this.scrobble,
    required this.syncFeedback,
  });

  factory ListenBrainzConfigModel.fromJson(Map<String, dynamic> json) =>
      _$ListenBrainzConfigModelFromJson(json);

  Map<String, dynamic> toJson() => _$ListenBrainzConfigModelToJson(this);
}
