import 'dart:convert';

import 'package:crossonic/repositories/api/models/media_model.dart';
import 'package:crossonic/repositories/api/models/scrobble.dart';
import 'package:crossonic/services/audio_player/audio_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Scrobbler {
  static const scrobbleCacheKey = "scrobble-cache";
  static const scrobbleCacheSizeKey = "scrobble-cache-size";

  bool _playing = false;
  DateTime? _playingSince;
  Media? _currentMedia;
  Duration _accumulatedDuration = Duration.zero;
  bool _scrobbled = false;
  final SharedPreferences _sharedPreferences;
  final List<Scrobble> _cachedScrobbles = [];
  bool _sendingCachedScrobbles = false;

  Future<void> _cacheScrobble(Scrobble scrobble) async {
    _cachedScrobbles.add(scrobble);
    await _sharedPreferences.setInt(
        scrobbleCacheSizeKey, _cachedScrobbles.length);
    await _sharedPreferences.setString(
        "$scrobbleCacheKey${_cachedScrobbles.length - 1}",
        jsonEncode(scrobble.toJson()));
  }

  Future<void> _loadCachedScrobbles() async {
    int size = _sharedPreferences.getInt(scrobbleCacheSizeKey) ?? 0;
    for (var i = 0; i < size; i++) {
      final scrobble = _sharedPreferences.getString("$scrobbleCacheKey$i");
      if (scrobble == null) continue;
      _cachedScrobbles.add(Scrobble.fromJson(jsonDecode(scrobble)));
    }
    await _sendScrobbleCache();
  }

  Future<void> _clearScrobbleCache() async {
    _cachedScrobbles.clear();
    int size = _sharedPreferences.getInt(scrobbleCacheSizeKey) ?? 0;
    for (var i = 0; i < size; i++) {
      await _sharedPreferences.remove("$scrobbleCacheKey$i");
    }
    await _sharedPreferences.remove(scrobbleCacheSizeKey);
  }

  Scrobbler.enable({
    required CrossonicAudioHandler audioHandler,
    required SharedPreferences sharedPreferences,
  }) : _sharedPreferences = sharedPreferences {
    audioHandler.crossonicPlaybackStatus.listen((value) {
      if (value.status == CrossonicPlaybackStatus.playing) {
        _setPlaying(true);
      } else {
        _setPlaying(false);
      }
    });
    audioHandler.mediaQueue.current.listen((value) {
      _updateCurrent(value?.item);
    });
    _loadCachedScrobbles();
  }

  void _updateCurrent(Media? media) {
    try {
      //_crossonicRepository.sendNowPlaying(media != null
      //    ? Scrobble(
      //        timeUnixMS: DateTime.now().millisecondsSinceEpoch,
      //        songID: media.id,
      //        songName: media.title,
      //        songDuration: media.duration,
      //        albumID: media.albumId,
      //        albumName: media.album,
      //        artistID: media.artistId,
      //        artistName: media.artist,
      //        musicBrainzID: media.musicBrainzId,
      //      )
      //    : null);
    } catch (e) {
      print("Failed to send now playing: $e");
    }
    _checkScrobble();
    _currentMedia = media;
    _playingSince = _playing ? DateTime.now() : null;
    _accumulatedDuration = Duration.zero;
    _scrobbled = false;
  }

  void _setPlaying(bool playing) {
    if (_playing == playing) return;
    _playing = playing;
    if (!playing) {
      if (_currentMedia != null && _playingSince != null) {
        _checkScrobble();
        _accumulatedDuration += DateTime.now().difference(_playingSince!);
        _playingSince = null;
      }
    } else {
      _playingSince = DateTime.now();
    }
  }

  void _checkScrobble() {
    if (_currentMedia != null) {
      final duration = (_playingSince != null
              ? DateTime.now().difference(_playingSince!)
              : Duration.zero) +
          _accumulatedDuration;
      final songDuration = _currentMedia?.duration != null
          ? Duration(seconds: _currentMedia!.duration!)
          : null;
      if (songDuration == null) {
        if (duration.inMinutes > 2) {
          _scrobble(
            media: _currentMedia!,
            duration: duration,
            time: DateTime.now(),
          );
        }
      } else {
        if (duration.inMinutes > 3 || duration > songDuration * 0.5) {
          _scrobble(
            media: _currentMedia!,
            duration: duration,
            time: DateTime.now(),
          );
        }
      }
    }
  }

  Future<void> _scrobble({
    required Media media,
    required Duration duration,
    required DateTime time,
  }) async {
    final update = _scrobbled;
    _scrobbled = true;
    final scrobble = Scrobble(
      timeUnixMS: time.millisecondsSinceEpoch,
      durationMS: duration.inMilliseconds,
      songID: media.id,
      songName: media.title,
      songDuration: media.duration,
      albumID: media.albumId,
      albumName: media.album,
      artistID: media.artistId,
      artistName: media.artist,
      musicBrainzID: media.musicBrainzId,
      update: update,
    );
    try {
      //await _crossonicRepository.sendScrobbles([scrobble]);
      _sendScrobbleCache();
    } catch (e) {
      print("Failed to send scrobble to server: $e");
      await _cacheScrobble(scrobble);
    }
  }

  Future<bool> _sendScrobbleCache() async {
    if (!_sendingCachedScrobbles && _cachedScrobbles.isNotEmpty) {
      _sendingCachedScrobbles = true;
      try {
        //await _crossonicRepository.sendScrobbles(_cachedScrobbles);
        await _clearScrobbleCache();
        return true;
      } finally {
        _sendingCachedScrobbles = false;
      }
    }
    return false;
  }
}
