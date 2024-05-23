import 'package:json_annotation/json_annotation.dart';

part 'listenbrainz_model.g.dart';

@JsonSerializable()
class ListenBrainzConfig {
  final String? listenBrainzUsername;

  ListenBrainzConfig({
    required this.listenBrainzUsername,
  });

  factory ListenBrainzConfig.fromJson(Map<String, dynamic> json) =>
      _$ListenBrainzConfigFromJson(json);
}
