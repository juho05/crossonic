import 'dart:async';
import 'dart:convert';

import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:crossonic/repositories/api/models/media_model.dart';
import 'package:crossonic/services/audio_handler/audio_handler.dart';
import 'package:crossonic/services/scrobble/scrobble.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Scrobbler {
  static const scrobbleCacheKey = "scrobble-cache";

  final SharedPreferences _sharedPreferences;
  final APIRepository _apiRepository;

  final List<Scrobble> _scrobbles = [];

  bool _playing = false;
  DateTime? _playingSince;
  Duration _accumulatedDuration = Duration.zero;
  bool _sendingCachedScrobbles = false;
  bool _hasCurrentMedia = false;
  Timer? _storeTimer;

  void _loadScrobbles() {
    if (_scrobbles.isNotEmpty) return;
    final json = _sharedPreferences.getString(scrobbleCacheKey);
    if (json == null) return;
    _scrobbles.addAll(
        (jsonDecode(json) as List<dynamic>).map((s) => Scrobble.fromJson(s)));
  }

  Future<void> _clearScrobbles() async {
    _scrobbles.clear();
    await _storeScrobbles();
  }

  Future<void> _storeScrobbles() async {
    if (_scrobbles.isEmpty) {
      await _sharedPreferences.remove(scrobbleCacheKey);
      return;
    }
    await _sharedPreferences.setString(
        scrobbleCacheKey, jsonEncode(_scrobbles));
  }

  Future<void> _updateScrobble(Duration duration) async {
    if (!_hasCurrentMedia) return;
    final current = _scrobbles.removeLast();
    _scrobbles.add(Scrobble(
      songID: current.songID,
      timeUnixMS: current.timeUnixMS,
      durationMS: duration.inMilliseconds,
    ));
    await _storeScrobbles();
  }

  Future<void> _newScrobble(String songID) async {
    _scrobbles.add(Scrobble(
      songID: songID,
      timeUnixMS: DateTime.now().millisecondsSinceEpoch,
      durationMS: 0,
    ));
    _hasCurrentMedia = true;
    await _storeScrobbles();
  }

  Scrobbler.enable({
    required CrossonicAudioHandler audioHandler,
    required SharedPreferences sharedPreferences,
    required APIRepository apiRepository,
  })  : _sharedPreferences = sharedPreferences,
        _apiRepository = apiRepository {
    _loadScrobbles();
    apiRepository.addBeforeLogoutCallback(() async {
      if (_playingSince != null) {
        _accumulatedDuration += DateTime.now().difference(_playingSince!);
        _playingSince = null;
        await _updateScrobble(_accumulatedDuration);
      }
      await _sendScrobbles();
    });
    apiRepository.authStatus.listen((status) async {
      if (status != AuthStatus.authenticated) {
        await _clearScrobbles();
      }
    });
    audioHandler.crossonicPlaybackStatus.listen((value) async {
      if (value.status == CrossonicPlaybackStatus.playing) {
        await _setPlaying(true);
      } else {
        await _setPlaying(
            false, value.status != CrossonicPlaybackStatus.stopped);
      }
    });
    audioHandler.mediaQueue.current.listen((value) async {
      await _updateCurrent(value?.item);
    });
  }

  Future<void> _updateCurrent(Media? media) async {
    try {
      if (media != null) {
        await _apiRepository.sendNowPlaying(media.id);
      }
    } catch (e) {
      print("Failed to send now playing: $e");
    }
    if (_playingSince != null) {
      _accumulatedDuration += DateTime.now().difference(_playingSince!);
    }
    if (_accumulatedDuration > Duration.zero) {
      await _updateScrobble(_accumulatedDuration);
    }
    _playingSince = _playing ? DateTime.now() : null;
    _accumulatedDuration = Duration.zero;
    _hasCurrentMedia = false;
    await _sendScrobbles();
    if (media != null) {
      await _newScrobble(media.id);
    }
  }

  Future<void> _setPlaying(bool playing, [bool updateScrobble = true]) async {
    if (_playing == playing) return;
    _playing = playing;
    if (!playing) {
      if (_playingSince != null) {
        if (updateScrobble) {
          _accumulatedDuration += DateTime.now().difference(_playingSince!);
          _playingSince = null;
          await _updateScrobble(_accumulatedDuration);
        }
      }
      _storeTimer?.cancel();
      _storeTimer = null;
    } else {
      _playingSince = DateTime.now();
      _storeTimer ??=
          Timer.periodic(const Duration(seconds: 10), (timer) async {
        if (!_hasCurrentMedia) return;
        if (_playingSince != null) {
          _accumulatedDuration += DateTime.now().difference(_playingSince!);
          _playingSince = _playing ? DateTime.now() : null;
        }
        if (updateScrobble) {
          await _updateScrobble(_accumulatedDuration);
        }
      });
    }
  }

  Future<void> _sendScrobbles() async {
    if (!_sendingCachedScrobbles) {
      _sendingCachedScrobbles = true;
      try {
        _scrobbles.removeWhere((s) => s.durationMS < 1000);
        if (_scrobbles.isNotEmpty) {
          await _apiRepository.submitScrobbles(_scrobbles.map((s) =>
              ScrobbleData(
                  id: s.songID,
                  timeUnixMS: s.timeUnixMS,
                  durationMS: s.durationMS)));
          await _clearScrobbles();
        }
      } catch (e) {
        print("Failed to scrobble: $e");
      }
      _sendingCachedScrobbles = false;
    }
  }
}
