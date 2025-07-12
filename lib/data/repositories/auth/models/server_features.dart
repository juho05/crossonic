import 'package:crossonic/data/repositories/version/version.dart';
import 'package:json_annotation/json_annotation.dart';

part 'server_features.g.dart';

@JsonSerializable()
class ServerFeatures {
  final bool isOpenSubsonic;
  final bool isCrossonic;
  final bool supportsPasswordAuth;
  final bool supportsTokenAuth;
  final bool loadedExtensions;
  final Set<int> formPost;
  final Set<int> transcodeOffset;
  final Set<int> songLyrics;
  final Set<int> apiKeyAuthentication;
  final Version? crossonicVersion;

  ServerFeatures({
    this.isOpenSubsonic = false,
    this.isCrossonic = false,
    this.supportsPasswordAuth = false,
    this.supportsTokenAuth = false,
    this.loadedExtensions = false,
    this.formPost = const {},
    this.transcodeOffset = const {},
    this.songLyrics = const {},
    this.apiKeyAuthentication = const {},
    this.crossonicVersion,
  });

  ServerFeatures copyWith({
    bool? isOpenSubsonic,
    bool? isCrossonic,
    bool? supportsPasswordAuth,
    bool? supportsTokenAuth,
    bool? loadedExtensions,
    Set<int>? formPost,
    Set<int>? transcodeOffset,
    Set<int>? songLyrics,
    Set<int>? apiKeyAuthentication,
    required Version? crossonicVersion,
  }) =>
      ServerFeatures(
        isOpenSubsonic: isOpenSubsonic ?? this.isOpenSubsonic,
        isCrossonic: isCrossonic ?? this.isCrossonic,
        supportsPasswordAuth: supportsPasswordAuth ?? this.supportsPasswordAuth,
        supportsTokenAuth: supportsTokenAuth ?? this.supportsTokenAuth,
        loadedExtensions: loadedExtensions ?? this.loadedExtensions,
        formPost: formPost ?? this.formPost,
        transcodeOffset: transcodeOffset ?? this.transcodeOffset,
        songLyrics: songLyrics ?? this.songLyrics,
        apiKeyAuthentication: apiKeyAuthentication ?? this.apiKeyAuthentication,
        crossonicVersion: crossonicVersion,
      );

  factory ServerFeatures.fromJson(Map<String, dynamic> json) =>
      _$ServerFeaturesFromJson(json);

  Map<String, dynamic> toJson() => _$ServerFeaturesToJson(this);
}
