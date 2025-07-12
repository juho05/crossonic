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

  List<(String, String)> _fields = const [];
  List<(String, String)> get fields => _fields;

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
      ("ID", s.id),
      if (s.musicBrainzId != null) ("MBID", s.musicBrainzId!),
      if (s.duration != null)
        ("Duration", formatDuration(Duration(seconds: s.duration!))),
      if (s.playCount != null) ("Play count", s.playCount.toString()),
      if (s.played != null) ("Last played", formatDateTime(s.played!)),
      if (s.starred != null) ("Favorited", formatDateTime(s.starred!)),
      if (s.userRating != null) ("User rating", s.userRating.toString()),
      if (s.averageRating != null)
        (
          "Average rating",
          formatDouble(s.averageRating!),
        ),
      if ((s.genres == null || s.genres!.isEmpty) && s.genre != null)
        ("Genres", s.genre!),
      if (s.genres != null && s.genres!.isNotEmpty)
        ("Genres", s.genres!.map((g) => g.name).join(", ")),
      if (s.year != null) ("Year", s.year.toString()),
      if (s.sortName != null) ("Sort name", s.sortName!),
      if (s.moods != null && s.moods!.isNotEmpty)
        ("Moods", s.moods!.join(", ")),
      if (s.explicitStatus != null)
        ("Explicit", formatBoolToYesNo(s.explicitStatus == "explicit")),
      if (s.contentType != null) ("Content type", s.contentType!),
      if (s.bitRate != null) ("Bitrate", "${s.bitRate!} kbps"),
      if (s.samplingRate != null) ("Sample rate", "${s.samplingRate!} Hz"),
      if (s.bitDepth != null) ("Bit depth", "${s.bitDepth!} bit"),
      if (s.channelCount != null) ("Channels", s.channelCount!.toString()),
      if (s.bpm != null) ("BPM", s.bpm!.toString()),
      if (s.replayGain != null && s.replayGain!.trackGain != null)
        ("Track gain", "${formatDouble(s.replayGain!.trackGain!)} dB"),
      if (s.replayGain != null && s.replayGain!.trackGain != null)
        ("Album gain", "${formatDouble(s.replayGain!.albumGain!)} dB"),
      if (s.replayGain != null && s.replayGain!.fallbackGain != null)
        ("Fallback gain", "${formatDouble(s.replayGain!.fallbackGain!)} dB"),
      if (s.size != null)
        ("Size", "${formatDouble(s.size! / 1000000.0, precision: 2)} MB")
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
      ("ID", a.id),
      if (a.musicBrainzId != null) ("MBID", a.musicBrainzId!),
      ("Duration", formatDuration(Duration(seconds: a.duration))),
      ("Song count", a.songCount.toString()),
      if (a.playCount != null) ("Play count", a.playCount.toString()),
      if (a.played != null) ("Last played", formatDateTime(a.played!)),
      if (a.starred != null) ("Favorited", formatDateTime(a.starred!)),
      if (a.userRating != null) ("User rating", a.userRating.toString()),
      if ((a.genres == null || a.genres!.isEmpty) && a.genre != null)
        ("Genres", a.genre!),
      if (a.genres != null && a.genres!.isNotEmpty)
        ("Genres", a.genres!.map((g) => g.name).join(", ")),
      if (a.releaseDate == null && a.year != null) ("Year", a.year.toString()),
      if (a.releaseDate != null)
        (
          "Release date",
          formatDate(DateTime(a.releaseDate!.year ?? 0,
              a.releaseDate!.month ?? 1, a.releaseDate!.day ?? 1))
        ),
      if (a.originalReleaseDate != null)
        (
          "Original release date",
          formatDate(DateTime(
              a.originalReleaseDate!.year ?? 0,
              a.originalReleaseDate!.month ?? 1,
              a.originalReleaseDate!.day ?? 1)),
        ),
      ("Compilation", formatBoolToYesNo(a.isCompilation ?? false)),
      if (a.sortName != null) ("Sort name", a.sortName!),
      if (a.releaseTypes != null && a.releaseTypes!.isNotEmpty)
        ("Release types", a.releaseTypes!.join(", ")),
      if (a.moods != null && a.moods!.isNotEmpty)
        ("Moods", a.moods!.join(", ")),
      if (a.recordLabels != null && a.recordLabels!.isNotEmpty)
        ("Record labels", a.recordLabels!.map((l) => l.name).join(", ")),
      if (a.explicitStatus != null)
        ("Explicit", formatBoolToYesNo(a.explicitStatus == "explicit")),
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
      ("ID", a.id),
      if (a.musicBrainzId != null) ("MBID", a.musicBrainzId!),
      if (a.albumCount != null) ("Album count", a.albumCount.toString()),
      if (a.starred != null) ("Favorited", formatDateTime(a.starred!)),
      if (a.userRating != null) ("User rating", a.userRating.toString()),
      if (a.sortName != null) ("Sort name", a.sortName!),
      if (a.roles != null && a.roles!.isNotEmpty)
        ("Roles", a.roles!.join(", ")),
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
      ("ID", p.id),
      ("Created", formatDateTime(p.created)),
      ("Updated", formatDateTime(p.changed)),
      ("Song count", p.songCount.toString()),
      ("Duration", formatDuration(Duration(seconds: p.duration))),
      if (p.public != null) ("Public", formatBoolToYesNo(p.public!)),
      if (p.owner != null) ("Owner", p.owner!),
    ];

    _status = FetchStatus.success;
    notifyListeners();
  }
}
