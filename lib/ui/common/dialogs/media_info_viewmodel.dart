import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/format.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/foundation.dart';

class MediaInfoDialogViewModel extends ChangeNotifier {
  final SubsonicService _subsonic;
  final AuthRepository _auth;

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  String _name = "";
  String get name => _name;

  List<(String, String, Uri?)> _fields = const [];
  List<(String, String, Uri?)> get fields => _fields;

  MediaInfoDialogViewModel.song({
    required SubsonicService subsonicService,
    required AuthRepository authRepository,
    required String id,
  })  : _subsonic = subsonicService,
        _auth = authRepository {
    _loadSong(id);
  }

  MediaInfoDialogViewModel.album({
    required SubsonicService subsonicService,
    required AuthRepository authRepository,
    required String id,
  })  : _subsonic = subsonicService,
        _auth = authRepository {
    _loadAlbum(id);
  }

  MediaInfoDialogViewModel.artist({
    required SubsonicService subsonicService,
    required AuthRepository authRepository,
    required String id,
  })  : _subsonic = subsonicService,
        _auth = authRepository {
    _loadArtist(id);
  }

  MediaInfoDialogViewModel.playlist({
    required SubsonicService subsonicService,
    required AuthRepository authRepository,
    required String id,
  })  : _subsonic = subsonicService,
        _auth = authRepository {
    _loadPlaylist(id);
  }

  Future<void> _loadSong(String id) async {
    if (_status == FetchStatus.loading) return;
    _status = FetchStatus.loading;
    notifyListeners();

    final result = await _subsonic.getSong(_auth.con, id);
    switch (result) {
      case Err():
        _status = FetchStatus.failure;
        return;
      case Ok():
    }

    final s = result.value;
    _name = s.title;

    _fields = [
      ("ID", s.id, null),
      if (_exists(s.musicBrainzId))
        (
          "MBID",
          s.musicBrainzId!,
          _mbidToUrlIfCrossonic(s.musicBrainzId!, "recording"),
        ),
      if (s.duration != null)
        ("Duration", formatDuration(Duration(seconds: s.duration!)), null),
      if (s.playCount != null) ("Play count", s.playCount.toString(), null),
      if (s.played != null) ("Last played", formatDateTime(s.played!), null),
      if (s.starred != null) ("Favorited", formatDateTime(s.starred!), null),
      if (s.userRating != null && s.userRating != 0)
        ("User rating", s.userRating.toString(), null),
      if (s.averageRating != null && s.averageRating != 0)
        (
          "Average rating",
          formatDouble(s.averageRating!),
          null,
        ),
      if ((s.genres == null || s.genres!.isEmpty) && _exists(s.genre))
        ("Genres", s.genre!, null),
      if (s.genres != null && s.genres!.isNotEmpty)
        ("Genres", s.genres!.map((g) => g.name).join(", "), null),
      if ((s.releaseDate?.year == null ||
              s.originalReleaseDate?.year == null) &&
          s.year != null)
        ("Year", s.year.toString(), null),
      if (s.releaseDate?.year != null)
        (
          "Release date",
          formatDate(DateTime(s.releaseDate!.year!, s.releaseDate!.month ?? 1,
              s.releaseDate!.day ?? 1)),
          null,
        ),
      if (s.originalReleaseDate?.year != null)
        (
          "Original release date",
          formatDate(DateTime(
              s.originalReleaseDate!.year!,
              s.originalReleaseDate!.month ?? 1,
              s.originalReleaseDate!.day ?? 1)),
          null,
        ),
      if (_exists(s.sortName)) ("Sort name", s.sortName!, null),
      if (s.moods != null && s.moods!.isNotEmpty)
        ("Moods", s.moods!.join(", "), null),
      if (_exists(s.explicitStatus))
        ("Explicit", formatBoolToYesNo(s.explicitStatus == "explicit"), null),
      if (_exists(s.contentType)) ("Content type", s.contentType!, null),
      if (s.bitRate != null) ("Bitrate", "${s.bitRate!} kbps", null),
      if (s.samplingRate != null)
        ("Sample rate", "${s.samplingRate!} Hz", null),
      if (s.bitDepth != null) ("Bit depth", "${s.bitDepth!} bit", null),
      if (s.channelCount != null)
        ("Channels", s.channelCount!.toString(), null),
      if (s.bpm != null && s.bpm != 0) ("BPM", s.bpm!.toString(), null),
      if (s.replayGain != null && s.replayGain!.trackGain != null)
        ("Track gain", "${formatDouble(s.replayGain!.trackGain!)} dB", null),
      if (s.replayGain != null && s.replayGain!.trackGain != null)
        ("Album gain", "${formatDouble(s.replayGain!.albumGain!)} dB", null),
      if (s.replayGain != null && s.replayGain!.fallbackGain != null)
        (
          "Fallback gain",
          "${formatDouble(s.replayGain!.fallbackGain!)} dB",
          null
        ),
      if (s.size != null)
        ("Size", "${formatDouble(s.size! / 1000000.0, precision: 2)} MB", null)
    ];

    _status = FetchStatus.success;
    notifyListeners();
  }

  Future<void> _loadAlbum(String id) async {
    if (_status == FetchStatus.loading) return;
    _status = FetchStatus.loading;
    notifyListeners();

    final result = await _subsonic.getAlbum(_auth.con, id);
    switch (result) {
      case Err():
        _status = FetchStatus.failure;
        return;
      case Ok():
    }

    final a = result.value;
    _name = a.name;

    _fields = [
      ("ID", a.id, null),
      if (_exists(a.musicBrainzId))
        (
          a.releaseMbid != null ? "Release group MBID" : "MBID",
          a.musicBrainzId!,
          _mbidToUrlIfCrossonic(a.musicBrainzId!, "release-group")
        ),
      if (_exists(a.releaseMbid))
        (
          "Release MBID",
          a.releaseMbid!,
          _mbidToUrlIfCrossonic(a.releaseMbid!, "release")
        ),
      ("Duration", formatDuration(Duration(seconds: a.duration)), null),
      ("Song count", a.songCount.toString(), null),
      if (a.playCount != null) ("Play count", a.playCount.toString(), null),
      if (a.played != null) ("Last played", formatDateTime(a.played!), null),
      if (a.starred != null) ("Favorited", formatDateTime(a.starred!), null),
      if (a.userRating != null && a.userRating != 0)
        ("User rating", a.userRating.toString(), null),
      if (a.averageRating != null && a.averageRating != 0)
        (
          "Average rating",
          formatDouble(a.averageRating!),
          null,
        ),
      if ((a.genres == null || a.genres!.isEmpty) && _exists(a.genre))
        ("Genres", a.genre!, null),
      if (a.genres != null && a.genres!.isNotEmpty)
        ("Genres", a.genres!.map((g) => g.name).join(", "), null),
      if ((a.releaseDate?.year == null ||
              a.originalReleaseDate?.year == null) &&
          a.year != null)
        ("Year", a.year.toString(), null),
      if (a.releaseDate?.year != null)
        (
          "Release date",
          formatDate(DateTime(a.releaseDate!.year ?? 0,
              a.releaseDate!.month ?? 1, a.releaseDate!.day ?? 1)),
          null,
        ),
      if (a.originalReleaseDate?.year != null)
        (
          "Original release date",
          formatDate(DateTime(
              a.originalReleaseDate!.year ?? 0,
              a.originalReleaseDate!.month ?? 1,
              a.originalReleaseDate!.day ?? 1)),
          null,
        ),
      if (_exists(a.version)) ("Version", a.version!, null),
      if (a.isCompilation ?? false)
        ("Compilation", formatBoolToYesNo(a.isCompilation!), null),
      if (_exists(a.sortName)) ("Sort name", a.sortName!, null),
      if (a.releaseTypes != null && a.releaseTypes!.isNotEmpty)
        ("Release types", a.releaseTypes!.join(", "), null),
      if (a.moods != null && a.moods!.isNotEmpty)
        ("Moods", a.moods!.join(", "), null),
      if (a.recordLabels != null && a.recordLabels!.isNotEmpty)
        ("Record labels", a.recordLabels!.map((l) => l.name).join(", "), null),
      if (_exists(a.explicitStatus))
        ("Explicit", formatBoolToYesNo(a.explicitStatus == "explicit"), null),
    ];

    _status = FetchStatus.success;
    notifyListeners();
  }

  Future<void> _loadArtist(String id) async {
    if (_status == FetchStatus.loading) return;
    _status = FetchStatus.loading;
    notifyListeners();

    final result = await _subsonic.getArtist(_auth.con, id);
    switch (result) {
      case Err():
        _status = FetchStatus.failure;
        return;
      case Ok():
    }

    final a = result.value;
    _name = a.name;

    _fields = [
      ("ID", a.id, null),
      if (_exists(a.musicBrainzId))
        (
          "MBID",
          a.musicBrainzId!,
          _mbidToUrlIfCrossonic(a.musicBrainzId!, "artist")
        ),
      if (a.albumCount != null) ("Releases", a.albumCount.toString(), null),
      if (a.starred != null) ("Favorited", formatDateTime(a.starred!), null),
      if (a.userRating != null && a.userRating != 0)
        ("User rating", a.userRating.toString(), null),
      if (a.averageRating != null && a.averageRating != 0)
        (
          "Average rating",
          formatDouble(a.averageRating!),
          null,
        ),
      if (_exists(a.sortName)) ("Sort name", a.sortName!, null),
      if (a.roles != null && a.roles!.isNotEmpty)
        ("Roles", a.roles!.join(", "), null),
    ];

    _status = FetchStatus.success;
    notifyListeners();
  }

  Future<void> _loadPlaylist(String id) async {
    if (_status == FetchStatus.loading) return;
    _status = FetchStatus.loading;
    notifyListeners();

    final result = await _subsonic.getPlaylist(_auth.con, id);
    switch (result) {
      case Err():
        _status = FetchStatus.failure;
        return;
      case Ok():
    }

    final p = result.value;
    _name = p.name;

    _fields = [
      ("ID", p.id, null),
      ("Created", formatDateTime(p.created), null),
      ("Updated", formatDateTime(p.changed), null),
      ("Song count", p.songCount.toString(), null),
      ("Duration", formatDuration(Duration(seconds: p.duration)), null),
      if (p.public != null) ("Public", formatBoolToYesNo(p.public!), null),
      if (_exists(p.owner)) ("Owner", p.owner!, null),
    ];

    _status = FetchStatus.success;
    notifyListeners();
  }

  Uri? _mbidToUrlIfCrossonic(String mbid, String type) {
    if (!_auth.serverFeatures.isCrossonic) return null;
    return Uri(
      scheme: "https",
      host: "musicbrainz.org",
      pathSegments: [type, mbid],
    );
  }

  bool _exists(String? str) {
    if (str == null) return false;
    if (str.isEmpty) return false;
    return true;
  }
}
