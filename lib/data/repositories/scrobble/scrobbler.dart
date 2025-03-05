import 'dart:async';

import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/services/database/database.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:crossonic/utils/result.dart';
import 'package:drift/drift.dart';

class _Scrobble {
  String songId;
  DateTime time;
  Duration listenDuration;
  Duration? songDuration;

  _Scrobble({
    required this.songId,
    required this.time,
    required this.listenDuration,
    required this.songDuration,
  });
}

class Scrobbler {
  static const scrobbleCacheKey = "scrobble-cache";

  final SubsonicService _subsonic;
  final Database _db;
  final AuthRepository _auth;

  _Scrobble? _current;
  bool _submitting = false;
  bool _playing = false;
  DateTime? _playingSince;

  Scrobbler.enable({
    required AudioHandler audioHandler,
    required Database database,
    required AuthRepository authRepository,
    required SubsonicService subsonicService,
  })  : _db = database,
        _subsonic = subsonicService,
        _auth = authRepository {
    _auth.addListener(_onAuthChanged);
    audioHandler.queue.current.listen(_onCurrentChanged);
    audioHandler.playbackStatus.listen(_onPlaybackStatusChanged);
  }

  Future<void> _onCurrentChanged(
      ({bool fromAdvance, Song? song}) current) async {
    await _updateCurrent();
    _current = null;
    await _submitScrobbles();
    if (current.song == null) {
      return;
    }
    _current = _Scrobble(
      songId: current.song!.id,
      time: DateTime.now(),
      listenDuration: Duration.zero,
      songDuration: current.song!.duration,
    );
    final result = await _subsonic.scrobble(
        _auth.con,
        [
          (
            songId: _current!.songId,
            time: _current!.time,
            listenDuration: _current!.listenDuration
          )
        ],
        false,
        false);
    if (result is Err) {
      print("Failed to upload now playing: ${result.error}");
    }
  }

  Future<void> _onPlaybackStatusChanged(PlaybackStatus status) async {
    await _setPlaying(status == PlaybackStatus.playing);
  }

  Timer? _storeCurrentTimer;
  Future<void> _setPlaying(bool playing) async {
    if (_playing == playing) return;
    _playing = playing;
    await _updateCurrent();
    if (_playing) {
      _storeCurrentTimer ??=
          Timer.periodic(const Duration(seconds: 10), (timer) async {
        if (_current == null) return;
        await _updateCurrent();
      });
    } else {
      _storeCurrentTimer?.cancel();
      _storeCurrentTimer = null;
    }
  }

  Future<void> _submitScrobbles() async {
    if (!_auth.isAuthenticated) return;
    if (_submitting) return;
    _submitting = true;
    try {
      final scrobbles = await _db.managers.scrobble.filter((f) {
        if (_auth.serverFeatures.isCrossonic) {
          return (f.songId(_current?.songId) & f.startTime(_current?.time))
                  .not() &
              f.listenDurationMs.isBiggerOrEqualTo(1000);
        }
        return (f.songId(_current?.songId) & f.startTime(_current?.time))
                .not() &
            ((f.songDurationMs.isNull().not() &
                    f.listenDurationMs.isBiggerOrEqualTo(10000)) |
                (f.listenDurationMs.isBiggerOrEqualTo(
                        Duration(minutes: 4).inMilliseconds) |
                    f.listenDurationMs.column.isBiggerOrEqual(
                        f.songDurationMs.column / Variable(2))));
      }).get();
      if (scrobbles.isNotEmpty) {
        print("Uploading scrobbles:");
        for (var s in scrobbles) {
          print(
              "  - ${s.startTime}: ${s.songId} (${Duration(milliseconds: s.listenDurationMs)})");
        }
        final result = await _subsonic.scrobble(
          _auth.con,
          scrobbles.map((s) => (
                songId: s.songId,
                time: s.startTime,
                listenDuration: Duration(milliseconds: s.listenDurationMs)
              )),
          true,
          _auth.serverFeatures.isCrossonic,
        );
        if (result is Err) {
          bool success = false;
          for (var s in scrobbles) {
            final r = await _subsonic.scrobble(
              _auth.con,
              [
                (
                  songId: s.songId,
                  time: s.startTime,
                  listenDuration: Duration(milliseconds: s.listenDurationMs),
                ),
              ],
              true,
              _auth.serverFeatures.isCrossonic,
            );
            if (r is Ok) {
              success = true;
            } else {
              print("Failed to upload scrobble: $s");
            }
          }
          if (!success) {
            throw result.error;
          }
        }
      }
      await _db.managers.scrobble
          .filter((f) =>
              (f.songId(_current?.songId) & f.startTime(_current?.time)).not())
          .delete();
    } finally {
      _submitting = false;
    }
  }

  Future<void> _updateCurrent() async {
    if (_current == null) return;
    if (_playingSince != null) {
      _current!.listenDuration += DateTime.now().difference(_playingSince!);
    }
    _playingSince = _playing ? DateTime.now() : null;
    await _db.managers.scrobble.create(
      (o) => o(
        songId: _current!.songId,
        startTime: _current!.time,
        listenDurationMs: _current!.listenDuration.inMilliseconds,
        songDurationMs: Value(_current!.songDuration?.inMilliseconds),
      ),
      mode: InsertMode.replace,
    );
  }

  void _onAuthChanged() async {
    if (_auth.isAuthenticated) {
      await _submitScrobbles();
      return;
    }
    _current = null;
  }

  void dispose() {
    _storeCurrentTimer?.cancel();
    _auth.removeListener(_onAuthChanged);
  }
}
