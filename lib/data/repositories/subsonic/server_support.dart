import 'package:crossonic/data/repositories/auth/models/server_features.dart';
import 'package:crossonic/data/repositories/settings/transcoding.dart';
import 'package:crossonic/data/repositories/version/version.dart';

class ServerSupport {
  // auth types
  bool get apiKeyAuth => _features.apiKeyAuthentication.contains(1);
  bool get tokenAuth => _features.supportsTokenAuth;
  bool get passwordAuth => _features.supportsPasswordAuth;

  // OpenSubsonic
  bool get formPost => _features.formPost.contains(1);
  bool get transcodeOffset => _features.transcodeOffset.contains(1);
  bool get songLyricsById => _features.songLyrics.contains(1);
  bool get emptySearchString => _features.isOpenSubsonic;

  // Crossonic
  bool get changePlaylistCover => _features.isCrossonic;
  bool get scrobbleDuration => _features.isCrossonic;
  bool get listenBrainzConfig => _features.isCrossonic;
  bool get searchOnlyAlbumArtistsParam =>
      _features.isMinCrossonicVersion(const Version(major: 0, minor: 3));
  bool get appearsOn =>
      _features.isMinCrossonicVersion(const Version(major: 0, minor: 3));
  bool get listenBrainzSettings =>
      _features.isMinCrossonicVersion(const Version(major: 0, minor: 3));
  bool get getSongs =>
      _features.isMinCrossonicVersion(const Version(major: 0, minor: 3));

  bool get scanType =>
      _features.isMinCrossonicVersion(const Version(major: 0, minor: 2)) ||
      _features.isNavidrome;

  List<TranscodingCodec> get transcodeCodecs => _features.isCrossonic
      ? [
          TranscodingCodec.serverDefault,
          TranscodingCodec.raw,
          TranscodingCodec.mp3,
          TranscodingCodec.opus,
          TranscodingCodec.vorbis,
        ]
      : [
          TranscodingCodec.serverDefault,
          TranscodingCodec.raw,
        ];
  bool get albumMBIDIsReleaseGroupMBID => _features.isCrossonic;

  final ServerFeatures _features;
  ServerSupport({required ServerFeatures features}) : _features = features;
}
