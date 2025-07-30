import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:audio_player/audio_player.dart';
import 'package:audio_session/audio_session.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:crossonic/data/repositories/audio/queue/changable_queue.dart';
import 'package:crossonic/data/repositories/audio/queue/local_queue.dart';
import 'package:crossonic/data/repositories/audio/queue/media_queue.dart';
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
import 'package:crossonic/data/repositories/settings/replay_gain.dart';
import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:crossonic/data/repositories/settings/transcoding.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/version/version.dart';
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
  final SongDownloader _downloader;
  final KeyValueRepository _keyValue;

  final AudioPlayer _player;
  StreamSubscription? _playerEventSubscription;
  StreamSubscription? _restartPlaybackSubscription;

  final AudioSession _audioSession;
  StreamSubscription? _audioSessionInterruptionStream;
  StreamSubscription? _audioSessionBecomingNoisyStream;

  final MediaIntegration _integration;

  final BehaviorSubject<PlaybackStatus> _playbackStatus =
      BehaviorSubject.seeded(PlaybackStatus.stopped);
  ValueStream<PlaybackStatus> get playbackStatus => _playbackStatus.stream;

  (DateTime time, Duration position) _positionUpdate =
      (DateTime.now(), Duration.zero);

  Duration get position {
    if (_playbackStatus.value == PlaybackStatus.playing) {
      return _positionUpdate.$2 +
          (DateTime.now().difference(_positionUpdate.$1));
    }
    return _positionUpdate.$2;
  }

  Future<Duration> get bufferedPosition async => _player.initialized
      ? (await _player.bufferedPosition) + _positionOffset
      : Duration.zero;

  final ChangableQueue _queue = ChangableQueue(LocalQueue());
  StreamSubscription? _queueCurrentSubscription;

  Duration _positionOffset = Duration.zero;

  Timer? _disposePlayerTimer;

  bool _playOnNextMediaChange = false;

  (TranscodingCodec, int?) _transcoding;

  double _volume = 1;

  double get volume => _volume;
  set volume(double volume) {
    _volume = volume;
    _applyReplayGain();
  }

  bool _ducking = false;

  AudioHandler({
    required AudioPlayer player,
    required AudioSession audioSession,
    required MediaIntegration integration,
    required AuthRepository authRepository,
    required SubsonicService subsonicService,
    required SettingsRepository settingsRepository,
    required SongDownloader songDownloader,
    required KeyValueRepository keyValueRepository,
  })  : _player = player,
        _audioSession = audioSession,
        _integration = integration,
        _auth = authRepository,
        _subsonic = subsonicService,
        _settings = settingsRepository,
        _downloader = songDownloader,
        _transcoding = (
          settingsRepository.transcoding.codec,
          settingsRepository.transcoding.maxBitRate
        ),
        _keyValue = keyValueRepository {
    _integration
        .ensureInitialized(
      audioHandler: this,
      onPause: pause,
      onPlay: play,
      onPlayNext: playNext,
      onPlayPrev: playPrev,
      onSeek: seek,
      onStop: stop,
    )
        .then((value) async {
      _integration.updateMedia(null, null);
      _auth.addListener(_authChanged);

      _queueCurrentSubscription =
          _queue.currentAndNext.listen(_onCurrentOrNextChanged);

      _playerEventSubscription = _player.eventStream.listen(_playerEvent);
      _restartPlaybackSubscription =
          _player.restartPlayback.listen(_onRestartPlayback);

      _settings.replayGain.addListener(_onReplayGainChanged);
      _settings.transcoding.addListener(_onTranscodingChanged);
      _onTranscodingChanged();

      _audioSessionInterruptionStream =
          _audioSession.interruptionEventStream.listen((event) async {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _ducking = true;
              // ducking is automatically handled in _setPlayerVolume
              _setPlayerVolume(1);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              await pause();
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _ducking = false;
              _setPlayerVolume(1);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              await play();
              break;
          }
        }
      });

      _audioSessionBecomingNoisyStream =
          _audioSession.becomingNoisyEventStream.listen((_) async {
        await pause();
      });

      await _restoreQueue();

      _queue.addListener(
        () {
          _persistQueue();
        },
      );
    });
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
    _integration.updateMedia(null, null);
    _integration.updatePosition(Duration.zero);
    _integration.updatePlaybackState(PlaybackStatus.stopped);
    _positionOffset = Duration.zero;
    _playbackStatus.add(PlaybackStatus.stopped);
    _updatePosition(Duration.zero);
    if (_restoredQueue) {
      await _clearPersistentQueueData();
    }
    _queue.clear();
    await _disposePlayer();
  }

  Duration? _seekingPos;

  Future<void> seek(Duration pos) async {
    final song = _queue.current.value;
    if (song == null) return;
    await _ensurePlayerLoaded();
    _seekingPos = pos;
    _updatePosition();
    if ((!_auth.serverFeatures.transcodeOffset.contains(1) ||
            _player.canSeek) &&
        _positionOffset == Duration.zero) {
      await _player.seek(pos);
      _seekingPos = null;
    } else {
      _playbackStatus.add(PlaybackStatus.loading);
      await _player.setCurrent(_getStreamUri(song, pos));
      _positionOffset = pos;
      _seekingPos = null;
      _updatePosition();
    }
  }

  Future<void> _updatePosition([Duration? pos]) async {
    pos ??= _seekingPos;
    pos ??= await _player.position + _positionOffset;
    _positionUpdate = (DateTime.now(), pos);
    _integration.updatePosition(pos);
  }

  Future<void> playNext() async {
    if (!_queue.canAdvance) return;
    _queue.skipNext();
  }

  Future<void> playPrev() async {
    if (position.inSeconds > 3 || !_queue.canGoBack) {
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
    if (status == _playbackStatus.value) return;

    _audioSession.setActive(status == PlaybackStatus.playing);

    if (status == PlaybackStatus.stopped) {
      await stop();
      return;
    }

    final lastPos = position;

    _integration.updatePlaybackState(status);
    _playbackStatus.add(status);

    if (status == PlaybackStatus.playing) {
      _updatePosition();
    } else {
      _updatePosition(lastPos);
    }

    if (status != PlaybackStatus.playing && status != PlaybackStatus.loading) {
      // web browsers stop media os integration without active player
      if (!kIsWeb && _auth.serverFeatures.transcodeOffset.contains(1)) {
        _disposePlayerTimer ??=
            Timer(const Duration(minutes: 1), _disposePlayer);
      }
    } else {
      _disposePlayerTimer?.cancel();
      _disposePlayerTimer = null;
    }
  }

  Future<void> _onRestartPlayback(Duration pos) async {
    if (_queue.current.value == null) return;
    Log.warn("Restarting playback at position $pos");
    pos += _positionOffset;
    if (!_player.canSeek) {
      pos = Duration(seconds: (pos.inMilliseconds / 1000.0).round());
      _positionOffset = pos;
    }
    _updatePosition(pos);

    final canSeek = _downloader.getPath(_queue.current.value!.id) != null ||
        _transcoding.$1.name == "raw";

    final next = _queue.currentAndNext.value.next;
    await _player.setCurrent(
      _getStreamUri(_queue.current.value!, !canSeek ? pos : null),
      nextUrl: next != null ? _getStreamUri(next) : null,
      pos: canSeek ? pos : Duration.zero,
    );

    await _player.play();
  }

  Future<void> _onCurrentOrNextChanged(
      ({
        Song? current,
        Song? next,
        bool currentChanged,
        bool fromAdvance,
      }) event) async {
    final playAfterChange = _playOnNextMediaChange;
    _playOnNextMediaChange = false;
    if (event.current == null) {
      await stop();
      return;
    }
    await _ensurePlayerLoaded(false);
    if (event.currentChanged) {
      _positionOffset = Duration.zero;
      _updatePosition(Duration.zero);
      await _applyReplayGain();
    }

    if (event.currentChanged && !event.fromAdvance) {
      await _player.setCurrent(_getStreamUri(event.current!),
          nextUrl: event.next != null ? _getStreamUri(event.next!) : null);
      if (playAfterChange) {
        await _player.play();
      }
    } else {
      await _player
          .setNext(event.next != null ? _getStreamUri(event.next!) : null);
    }
    _integration.updateMedia(event.current,
        _subsonic.getCoverUri(_auth.con, event.current!.coverId, size: 512));
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

  Future<void> _onTranscodingChanged() async {
    _transcoding = await _settings.transcoding.activeTranscoding();
    if (_queue.currentAndNext.value.next != null) {
      await _player.setNext(_getStreamUri(_queue.currentAndNext.value.next!));
    }
  }

  // ================ helpers ================

  Future<void> _applyReplayGain() async {
    if (!_player.initialized) return;
    ReplayGainMode mode = _settings.replayGain.mode;
    final media = _queue.current.value;
    if (mode == ReplayGainMode.disabled || media == null) {
      await _setPlayerVolume(1);
      return;
    }

    double gain = _settings.replayGain.fallbackGain;

    if (mode == ReplayGainMode.auto) {
      mode = ReplayGainMode.track;

      if (media.album != null) {
        bool previousIsSameAlbum = true;
        if (_queue.currentIndex > 0) {
          final previous = _queue.regular.skip(_queue.currentIndex - 1).first;
          previousIsSameAlbum = previous.album?.id == media.album!.id;
        }

        final next = _queue.currentAndNext.value.next;
        bool nextIsSameAlbum =
            next == null || next.album?.id == media.album!.id;

        if (previousIsSameAlbum && nextIsSameAlbum && _queue.length > 1) {
          mode = ReplayGainMode.album;
        }
      }
    }

    if (media.trackGain != null &&
        (mode == ReplayGainMode.track || media.albumGain == null)) {
      gain = media.trackGain!;
    } else if (media.albumGain != null) {
      gain = media.albumGain!;
    } else if (_settings.replayGain.preferServerFallbackGain) {
      gain = media.fallbackGain ?? gain;
    }

    double volume = pow(10, gain / 20) as double;
    await _setPlayerVolume(volume);
  }

  Future<void> _setPlayerVolume(double volume) async {
    volume *= _volume;
    if (_ducking) {
      volume *= 0.5;
    }
    if (_player.volume == volume) return;
    await _player.setVolume(volume);
  }

  Future<void> _ensurePlayerLoaded([bool restorePlayerState = true]) async {
    if (_player.initialized) return;
    await _player.init();
    await _applyReplayGain();
    if (restorePlayerState) {
      await _restorePlayerState();
    }
  }

  Future<void> _restorePlayerState() async {
    final current = _queue.current.value;
    final next = _queue.currentAndNext.value.next;
    if (current != null) {
      if (_downloader.getPath(current.id) != null) {
        await _player.setCurrent(
          _getStreamUri(current),
          nextUrl: next != null ? _getStreamUri(next) : null,
          pos: position,
        );
        _positionOffset = Duration.zero;
      } else {
        _positionOffset = position;
        await _player.setCurrent(
          _getStreamUri(current, _positionOffset),
          nextUrl: next != null ? _getStreamUri(next) : null,
        );
      }
      if (_playbackStatus.value == PlaybackStatus.playing) {
        await play();
      } else {
        await pause();
      }
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
    await _audioSession.setActive(false);
  }

  Uri _getStreamUri(Song song, [Duration? offset]) {
    if (offset == null || offset == Duration.zero) {
      final path = _downloader.getPath(song.id);
      if (path != null) return path.toFileUri();
    }
    final query = _subsonic.generateQuery({
      "id": [song.id],
      "format": _transcoding.$1 != TranscodingCodec.serverDefault
          ? [_transcoding.$1.name]
          : [],
      "maxBitRate":
          _transcoding.$2 != null ? [_transcoding.$2!.toString()] : [],
      if (!_auth.serverFeatures
          .isMinCrossonicVersion(const Version(major: 0, minor: 0)))
        "timeOffset": offset != null ? [offset.inSeconds.toString()] : [],
      if (_auth.serverFeatures
          .isMinCrossonicVersion(const Version(major: 0, minor: 0)))
        "timeOffsetMs":
            offset != null ? [offset.inMilliseconds.toString()] : [],
    }, _auth.con.auth);
    return Uri.parse(
        '${_auth.con.baseUri}/rest/stream${Uri(queryParameters: query)}');
  }

  // ================ queue ================

  MediaQueue get queue => _queue;

  Future<void> changeQueue(MediaQueue queue) async {
    _playOnNextMediaChange = false;
    await _queue.change(queue);
  }

  static const String _queueCurrentSongKey = "queue_state.current_song";
  static const String _queueSongsKey = "queue_state.regular.songs";
  static const String _priorityQueueSongsKey = "queue_state.priority.songs";
  static const String _queueIndexKey = "queue_state.index";
  static const String _queueLoopingKey = "queue_state.looping";

  bool _restoredQueue = false;
  Future<void> _restoreQueue() async {
    final regular =
        (await _keyValue.loadObjectList(_queueSongsKey, Song.fromJson) ?? [])
            .toList();
    final priority = Queue<Song>.from(((await _keyValue.loadObjectList(
            _priorityQueueSongsKey, Song.fromJson)) ??
        []));
    final index = await _keyValue.loadInt(_queueIndexKey);
    final looping = (await _keyValue.loadBool(_queueLoopingKey)) ?? false;

    final currentSong =
        await _keyValue.loadObject(_queueCurrentSongKey, Song.fromJson);

    if (currentSong == null || index == null) {
      _queue.setLoop(looping);
      await _clearPersistentQueueData();
      _restoredQueue = true;
      return;
    }

    final loadedQueue = LocalQueue.withInitialData(
      regularQueue: regular.toList(),
      priorityQueue: priority,
      currentIndex: index,
      currentSong: currentSong,
      looping: looping,
    );

    await changeQueue(loadedQueue);

    _restoredQueue = true;

    _integration.updatePlaybackState(PlaybackStatus.paused);
    _integration.updateMedia(currentSong,
        _subsonic.getCoverUri(_auth.con, currentSong.coverId, size: 512));
  }

  void _persistQueue() async {
    Future.delayed(const Duration(milliseconds: 250), () async {
      if (_queue.current.value == null) {
        await _clearPersistentQueueData();
        return;
      }
      final looping = _queue.looping.value;
      await Future.wait([
        _keyValue.store(_queueSongsKey, _queue.regular.toList()),
        _keyValue.store(_priorityQueueSongsKey, _queue.priority.toList()),
        _keyValue.store(_queueLoopingKey, looping),
        _keyValue.store(_queueIndexKey, _queue.currentIndex),
        _keyValue.store(_queueCurrentSongKey, _queue.current.value),
      ]);
    });
  }

  Future<void> _clearPersistentQueueData() async {
    await Future.wait([
      _keyValue.remove(_queueCurrentSongKey),
      _keyValue.remove(_queueSongsKey),
      _keyValue.remove(_priorityQueueSongsKey),
      _keyValue.remove(_queueIndexKey),
    ]);
  }

  // =============== dispose ===============
  Future<void> dispose() async {
    await stop();
    // dispose queue
    await _queueCurrentSubscription?.cancel();
    _queue.dispose();

    await _audioSessionInterruptionStream?.cancel();
    await _audioSessionBecomingNoisyStream?.cancel();

    // dispose player
    await _playerEventSubscription?.cancel();
    await _restartPlaybackSubscription?.cancel();
    await _player.dispose();

    _settings.replayGain.removeListener(_onReplayGainChanged);
    _settings.transcoding.removeListener(_onTranscodingChanged);
    _auth.removeListener(_authChanged);
  }
}
