import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:crossonic/data/repositories/audio/queue/changable_queue.dart';
import 'package:crossonic/data/repositories/audio/queue/local_queue.dart';
import 'package:crossonic/data/repositories/audio/queue/media_queue.dart';
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/settings/replay_gain.dart';
import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/services/audio_players/player.dart';
import 'package:crossonic/data/services/media_integration/media_integration.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

enum PlaybackStatus {
  stopped,
  loading,
  playing,
  paused,
}

class AudioHandler {
  final AuthRepository _auth;
  final SubsonicService _subsonic;
  final SettingsRepository _settings;

  final AudioPlayer _player;
  StreamSubscription? _playerEventSubscription;

  final MediaIntegration _integration;

  final BehaviorSubject<PlaybackStatus> _playbackStatus =
      BehaviorSubject.seeded(PlaybackStatus.stopped);
  ValueStream<PlaybackStatus> get playbackStatus => _playbackStatus.stream;

  final BehaviorSubject<({Duration position, Duration? bufferedPosition})>
      _position =
      BehaviorSubject.seeded((position: Duration.zero, bufferedPosition: null));
  ValueStream<({Duration position, Duration? bufferedPosition})> get position =>
      _position.stream;

  final ChangableQueue _queue = ChangableQueue(LocalQueue());
  StreamSubscription? _queueCurrentSubscription;
  StreamSubscription? _queueNextSubscription;

  Duration _positionOffset = Duration.zero;
  Timer? _positionTimer;

  Timer? _disposePlayerTimer;

  bool _playOnNextMediaChange = false;

  AudioHandler({
    required AudioPlayer player,
    required MediaIntegration integration,
    required AuthRepository authRepository,
    required SubsonicService subsonicService,
    required SettingsRepository settingsRepository,
  })  : _player = player,
        _integration = integration,
        _auth = authRepository,
        _subsonic = subsonicService,
        _settings = settingsRepository {
    _auth.addListener(_authChanged);

    _queueCurrentSubscription = _queue.current.listen(_onCurrentChanged);
    _queueNextSubscription = _queue.next.listen(_onNextChanged);

    _integration.ensureInitialized(
      audioHandler: this,
      onPause: pause,
      onPlay: play,
      onPlayNext: playNext,
      onPlayPrev: playPrev,
      onSeek: seek,
      onStop: stop,
    );
    _integration.updateMedia(null, null);

    _playerEventSubscription = _player.eventStream.listen(_playerEvent);

    _settings.replayGain.addListener(_onReplayGainChanged);
  }

  // ================ playback controls ================

  void playOnNextMediaChange() {
    _playOnNextMediaChange = true;
  }

  Future<void> play() async {
    await _ensurePlayerLoaded();
    await _player.play();
  }

  Future<void> pause() async {
    await _ensurePlayerLoaded();
    await _player.pause();
  }

  Future<void> stop() async {
    _playOnNextMediaChange = false;
    _stopPositionTimer();
    _integration.updateMedia(null, null);
    _integration.updatePosition(Duration.zero);
    _integration.updatePlaybackState(PlaybackStatus.stopped);
    _positionOffset = Duration.zero;
    _queue.clear();
    await _disposePlayer();
  }

  Future<void> seek(Duration pos) async {
    final song = _queue.current.value.song;
    if (song == null) return;
    await _ensurePlayerLoaded();
    if (_player.canSeek && _positionOffset == Duration.zero) {
      await _player.seek(pos);
    } else {
      pos = Duration(seconds: pos.inSeconds);
      await _player.setCurrent(_getStreamUri(song, pos));
      _positionOffset = pos;
    }
    _position.add((position: pos, bufferedPosition: pos));
  }

  Future<void> playNext() async {
    if (!_queue.canAdvance) return;
    _queue.skipNext();
  }

  Future<void> playPrev() async {
    if (position.value.position.inSeconds > 3 || !_queue.canGoBack) {
      await seek(Duration.zero);
      return;
    }
    _queue.skipPrev();
  }

  // ================ callbacks ================

  Future<void> _playerEvent(AudioPlayerEvent event) async {
    if (!_player.initialized) return;
    if (event == AudioPlayerEvent.advance) {
      _queue.advance();
      return;
    }
    var status = switch (event) {
      AudioPlayerEvent.stopped => PlaybackStatus.stopped,
      AudioPlayerEvent.loading => PlaybackStatus.loading,
      AudioPlayerEvent.playing => PlaybackStatus.playing,
      AudioPlayerEvent.paused => PlaybackStatus.paused,
      AudioPlayerEvent.advance => throw Exception("should never happen"),
    };
    if (_queue.length == 0) {
      status = PlaybackStatus.stopped;
    }
    if (status == _playbackStatus.value) return;
    if (status == PlaybackStatus.stopped) {
      await stop();
      return;
    }
    _integration.updatePlaybackState(status);
    _playbackStatus.add(status);
    _updatePosition(true);
    if (status == PlaybackStatus.playing) {
      _startPositionTimer();
    } else {
      _stopPositionTimer();
    }

    if (status != PlaybackStatus.playing && status != PlaybackStatus.loading) {
      // web browsers stop media os integration without active player
      if (!kIsWeb) {
        _disposePlayerTimer ??=
            Timer(const Duration(minutes: 1), _disposePlayer);
      }
    } else {
      _disposePlayerTimer?.cancel();
      _disposePlayerTimer = null;
    }
  }

  Future<void> _onCurrentChanged(({Song? song, bool fromAdvance}) event) async {
    final playAfterChange = _playOnNextMediaChange;
    _playOnNextMediaChange = false;
    if (event.song == null) {
      await stop();
      return;
    }
    _positionOffset = Duration.zero;

    await _ensurePlayerLoaded(false);

    await _applyReplayGain();

    if (!event.fromAdvance) {
      await _player.setCurrent(_getStreamUri(event.song!));
      if (playAfterChange) {
        await _player.play();
      }
    }
    _integration.updateMedia(event.song, _getCoverUri(event.song!.coverId));
  }

  Future<void> _onNextChanged(Song? song) async {
    if (!_player.initialized && song != null) {
      await _ensurePlayerLoaded();
    }
    await _player.setNext(song != null ? _getStreamUri(song) : null);
  }

  Future<void> _authChanged() async {
    if (_auth.isAuthenticated) return;
    if (playbackStatus.value != PlaybackStatus.stopped) {
      await stop();
    }
  }

  Future<void> _onReplayGainChanged() async {
    await _applyReplayGain();
  }

  // ================ helpers ================

  Future<void> _applyReplayGain() async {
    if (!_player.initialized) return;
    ReplayGainMode mode = _settings.replayGain.mode;
    if (mode == ReplayGainMode.disabled) {
      if (_player.volume < 1) {
        print("replay gain disabled, settings volume to 1");
        _player.setVolume(1);
      }
      return;
    }
    final media = _queue.current.value.song;
    if (media == null) return;

    double gain = _settings.replayGain.fallbackGain;

    if (mode == ReplayGainMode.auto) {
      mode = ReplayGainMode.track;

      if (media.album != null) {
        bool previousIsSameAlbum = true;
        if (_queue.currentIndex > 0) {
          final previous = _queue.regular.skip(_queue.currentIndex - 1).first;
          previousIsSameAlbum = previous.album?.id == media.album!.id;
        }

        final next = _queue.next.value;
        bool nextIsSameAlbum =
            next == null || next.album?.id == media.album!.id;

        if (previousIsSameAlbum && nextIsSameAlbum && _queue.length > 1) {
          mode = ReplayGainMode.album;
        }
      }
    }

    if ((mode == ReplayGainMode.track && media.trackGain != null) ||
        media.albumGain == null) {
      gain = media.trackGain!;
    } else if (media.albumGain != null) {
      gain = media.albumGain!;
    } else if (_settings.replayGain.preferServerFallbackGain) {
      gain = media.fallbackGain ?? gain;
    }

    double volume = pow(10, gain / 20) as double;
    await _player.setVolume(volume);
  }

  Future<void> _ensurePlayerLoaded([bool restorePlayerState = true]) async {
    if (_player.initialized) return;
    _player.init();
    await _applyReplayGain();
    if (restorePlayerState) {
      await _restorePlayerState();
    }
  }

  Future<void> _restorePlayerState() async {
    final current = _queue.current.value.song;
    final next = _queue.next.value;
    if (current != null) {
      _positionOffset = position.value.position;
      await _player.setCurrent(_getStreamUri(current, position.value.position));
      if (_playbackStatus.value == PlaybackStatus.playing) {
        await play();
      } else {
        await pause();
      }
    }
    if (next != null) {
      await _player.setNext(_getStreamUri(next));
    }
    if (current == null && next == null) {
      await stop();
    }
  }

  Future<void> _disposePlayer() async {
    if (!_player.initialized ||
        _playbackStatus.value == PlaybackStatus.playing ||
        _playbackStatus.value == PlaybackStatus.loading) {
      return;
    }
    _player.setVolume(1);
    await _player.dispose();
  }

  void _startPositionTimer() {
    if (_positionTimer != null) return;
    int counter = 0;
    _positionTimer =
        Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (!kIsWeb && Platform.isLinux) {
        counter++;
      }
      _updatePosition(counter % 5 == 0);
    });
  }

  Future<void> _updatePosition(bool updateNative) async {
    if (_playbackStatus.value == PlaybackStatus.stopped) {
      _position.add((position: Duration.zero, bufferedPosition: null));
      if (updateNative) {
        _integration.updatePosition(Duration.zero);
      }
      return;
    }
    if (_playbackStatus.value != PlaybackStatus.playing &&
        _playbackStatus.value != PlaybackStatus.paused) {
      return;
    }

    await _ensurePlayerLoaded();

    final pos = await _player.position + _positionOffset;
    final bufferedPos = await _player.bufferedPosition + _positionOffset;

    _position.add((position: pos, bufferedPosition: bufferedPos));
    if (updateNative) {
      _integration.updatePosition(pos, bufferedPos);
    }
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  Uri _getStreamUri(Song song, [Duration? offset]) {
    final query = _subsonic.generateQuery({
      "id": [song.id],
      "format": [], // TODO
      "maxBitRate": [], // TODO
      "timeOffset": offset != null ? [offset.inSeconds.toString()] : [],
    }, _auth.con.auth);
    return Uri.parse(
        '${_auth.con.baseUri}/rest/stream${Uri(queryParameters: query)}');
  }

  Uri? _getCoverUri(String? coverId) {
    if (coverId == null) return null;
    final query = _subsonic.generateQuery({
      "id": [coverId],
    }, _auth.con.auth);
    return Uri.parse(
        '${_auth.con.baseUri}/rest/getCoverArt${Uri(queryParameters: query)}');
  }

  // ================ queue ================

  MediaQueue get queue => _queue;

  Future<void> changeQueue(MediaQueue queue) async {
    _playOnNextMediaChange = false;
    await _queue.change(queue);
  }

  // =============== dispose ===============
  Future<void> dispose() async {
    await stop();
    // dispose queue
    await _queueCurrentSubscription?.cancel();
    await _queueNextSubscription?.cancel();
    _queue.dispose();

    // dispose player
    await _playerEventSubscription?.cancel();
    await _player.dispose();

    _settings.replayGain.removeListener(_onReplayGainChanged);
    _auth.removeListener(_authChanged);
  }
}
