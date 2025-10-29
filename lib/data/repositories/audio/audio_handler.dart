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
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/data/services/media_integration/media_integration.dart';
import 'package:crossonic/utils/throttle.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

enum PlaybackStatus { stopped, loading, playing, paused }

class AudioHandler {
  final AuthRepository _auth;
  final SubsonicRepository _subsonic;
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

  (DateTime time, Duration position) _positionUpdate = (
    DateTime.now(),
    Duration.zero,
  );

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

  (TranscodingCodec, int) _transcoding;

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
    required SubsonicRepository subsonicRepository,
    required SettingsRepository settingsRepository,
    required SongDownloader songDownloader,
    required KeyValueRepository keyValueRepository,
  }) : _player = player,
       _audioSession = audioSession,
       _integration = integration,
       _auth = authRepository,
       _subsonic = subsonicRepository,
       _settings = settingsRepository,
       _downloader = songDownloader,
       _transcoding = (
         settingsRepository.transcoding.codec,
         settingsRepository.transcoding.maxBitRate,
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

          _queueCurrentSubscription = _queue.currentAndNext.listen(
            _onCurrentOrNextChanged,
          );

          _playerEventSubscription = _player.eventStream.listen(_playerEvent);
          _restartPlaybackSubscription = _player.restartPlayback.listen(
            (pos) => _restartPlayback(pos + _positionOffset),
          );

          _settings.replayGain.addListener(_onReplayGainChanged);
          _settings.transcoding.addListener(_onTranscodingChanged);
          _onTranscodingChanged();

          _audioSessionInterruptionStream = _audioSession
              .interruptionEventStream
              .listen((event) async {
                if (event.begin) {
                  switch (event.type) {
                    case AudioInterruptionType.duck:
                      Log.debug(
                        "received volume duck begin request from audio_session",
                      );
                      _ducking = true;
                      // ducking is automatically handled in _setPlayerVolume
                      _setPlayerVolume(1);
                      break;
                    case AudioInterruptionType.pause:
                      Log.debug(
                        "received pause begin request from audio_session",
                      );
                      await pause();
                      break;
                    case AudioInterruptionType.unknown:
                      Log.debug(
                        "received unknown begin request from audio_session",
                      );
                      await pause();
                      break;
                  }
                } else {
                  switch (event.type) {
                    case AudioInterruptionType.duck:
                      Log.debug(
                        "received volume duck end request from audio_session",
                      );
                      _ducking = false;
                      _setPlayerVolume(1);
                      break;
                    case AudioInterruptionType.pause:
                      Log.debug("received pause begin end from audio_session");
                      await play();
                      break;
                    case AudioInterruptionType.unknown:
                      Log.debug(
                        "received unknown end request from audio_session",
                      );
                      await play();
                      break;
                  }
                }
              });

          _audioSessionBecomingNoisyStream = _audioSession
              .becomingNoisyEventStream
              .listen((_) async {
                Log.debug("received becoming noisy event from audio_session");
                await pause();
              });

          await _restoreQueue();

          _queue.addListener(_persistQueue);
          _queue.currentAndNext.listen((_) => _persistQueue());
          _queue.looping.listen((_) => _persistQueue());
        });
  }

  // ================ playback controls ================

  void playOnNextMediaChange() {
    _playOnNextMediaChange = true;
    Log.trace("enabling playOnNextMediaChange");
  }

  Future<void> play() async {
    Log.trace("play");
    await _ensurePlayerLoaded();
    await _player.play();
  }

  Future<void> pause() async {
    Log.trace("pause");
    await _ensurePlayerLoaded();
    await _player.pause();
  }

  Future<void> stop() async {
    Log.trace("stop");
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
    Log.trace("seek to $pos");
    final song = _queue.current.value;
    if (song == null) return;
    await _ensurePlayerLoaded();
    _seekingPos = pos;
    _updatePosition();
    if ((!_subsonic.supports.transcodeOffset || _player.canSeek) &&
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
    Log.trace("updating current position: $pos");
    _positionUpdate = (DateTime.now(), pos);
    _integration.updatePosition(pos);
  }

  Future<void> playNext() async {
    Log.trace("play next");
    if (!_queue.canAdvance) {
      Log.warn("ignoring play next request because there is not next song");
      return;
    }
    _queue.skipNext();
  }

  Future<void> playPrev() async {
    Log.trace("play prev");
    if (position.inSeconds > 3 || !_queue.canGoBack) {
      if (!_queue.canGoBack) {
        Log.trace(
          "seeking back to beginning of current song because there is no previous song",
        );
      } else {
        Log.trace(
          "seeking back to beginning of current song because the current position is >3 s into the song: ${position.inSeconds}",
        );
      }
      await seek(Duration.zero);
      return;
    }
    Log.trace("going back one song in the queue");
    _queue.skipPrev();
  }

  // ================ callbacks ================

  Future<void> _playerEvent(AudioPlayerEvent event) async {
    if (!_player.initialized) {
      if (event != AudioPlayerEvent.stopped) {
        Log.warn(
          "ignoring a player event because the player is not initialized: ${event.name}",
        );
      }
      return;
    }
    Log.trace("player event received: ${event.name}");
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

    Log.debug("new player status: $status");

    _enableAudioSession(status == PlaybackStatus.playing);

    if (status == PlaybackStatus.stopped) {
      if (_queue.current.value == null ||
          (_queue.currentAndNext.value.next == null &&
              (_queue.current.value!.duration ?? Duration.zero) - position <
                  const Duration(seconds: 3))) {
        Log.debug(
          "stopping playback; current: ${_queue.current.value?.id}, next: ${_queue.currentAndNext.value.next?.id}, time to end of song: ${_queue.current.value?.duration ?? Duration.zero - position}",
        );
        await stop();
        return;
      }

      Log.warn(
        "received player status stop but there should still be a song playing",
      );

      await _restartPlayback(
        position,
        play: _playbackStatus.value == PlaybackStatus.playing,
      );

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
      if (!kIsWeb && _subsonic.supports.transcodeOffset) {
        if (_disposePlayerTimer == null) {
          Log.debug("enabling dispose player timer (1 minute)");
          _disposePlayerTimer = Timer(
            const Duration(minutes: 1),
            _disposePlayer,
          );
        }
      }
    } else if (_disposePlayerTimer != null) {
      Log.debug("canceling dispose player timer");
      _disposePlayerTimer?.cancel();
      _disposePlayerTimer = null;
    }
  }

  Future<void> _restartPlayback(Duration pos, {bool play = true}) async {
    if (_queue.current.value == null) return;
    Log.warn("Restarting playback at position $pos, play after restore: $play");

    final songDuration = _queue.current.value!.duration;

    if (songDuration != null &&
        songDuration - pos < const Duration(seconds: 1)) {
      Log.debug(
        "Target position of restart playback is at end of song, skipping to next song instead",
      );
      if (play) {
        playOnNextMediaChange();
      }
      await playNext();
      return;
    }

    _updatePosition(pos);

    _seekingPos = pos;

    final canSeek =
        _downloader.getPath(_queue.current.value!.id) != null ||
        _transcoding.$1 == TranscodingCodec.raw;

    final next = _queue.currentAndNext.value.next;
    await _player.setCurrent(
      _getStreamUri(_queue.current.value!, !canSeek ? pos : null),
      nextUrl: next != null ? _getStreamUri(next) : null,
      pos: canSeek ? pos : Duration.zero,
    );
    if (canSeek) {
      _positionOffset = Duration.zero;
    } else {
      _positionOffset = pos;
    }
    _seekingPos = null;

    if (play) {
      await _player.play();
    } else {
      await _player.pause();
    }
  }

  Future<void> _onCurrentOrNextChanged(
    ({Song? current, Song? next, bool currentChanged, bool fromAdvance}) event,
  ) async {
    final playAfterChange = _playOnNextMediaChange;
    _playOnNextMediaChange = false;
    if (event.current == null) {
      Log.trace("current song changed to null, calling stop...");
      await stop();
      return;
    }
    await _ensurePlayerLoaded(false);
    if (event.currentChanged) {
      Log.trace(
        "current song changed: ${event.current?.id}, from advance: ${event.fromAdvance}",
      );
      _positionOffset = Duration.zero;
      _updatePosition(Duration.zero);
      await _applyReplayGain();
    }

    if (event.currentChanged && !event.fromAdvance) {
      await _player.setCurrent(
        _getStreamUri(event.current!),
        nextUrl: event.next != null ? _getStreamUri(event.next!) : null,
      );
      if (playAfterChange) {
        await _player.play();
      }
    } else {
      Log.trace("next song changed: ${event.next?.id}");
      await _player.setNext(
        event.next != null ? _getStreamUri(event.next!) : null,
      );
    }
    _integration.updateMedia(
      event.current,
      _subsonic.getCoverUri(event.current!.coverId, size: 512),
    );
  }

  Future<void> _authChanged() async {
    if (_auth.isAuthenticated) return;
    if (playbackStatus.value != PlaybackStatus.stopped) {
      Log.debug("stopping playback because user logged out");
      await stop();
    }
  }

  Future<void> _onReplayGainChanged() async {
    await _applyReplayGain();
  }

  Future<void> _onTranscodingChanged() async {
    _transcoding = await _settings.transcoding.activeTranscoding();
    Log.debug(
      "current active transcoding profile: ${_transcoding.$1.name}${_transcoding.$1 != TranscodingCodec.raw ? "${_transcoding.$2} kbps" : ""}",
    );
    if (_queue.currentAndNext.value.next != null) {
      Log.trace("changing next url because transcoding profile changed");
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

    Log.trace("applying replay gain, mode: ${mode.name}");

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
      Log.warn(
        "using fallback gain because ${_queue.current.value?.id} has no replay gain metadata",
      );
    }

    Log.debug("replay gain of current song: $gain dB");

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
    Log.debug("reactivating player (restore state: $restorePlayerState)...");
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
        Log.trace("restoring position with player seek");
        await _player.setCurrent(
          _getStreamUri(current),
          nextUrl: next != null ? _getStreamUri(next) : null,
          pos: position,
        );
        _positionOffset = Duration.zero;
      } else {
        Log.trace("restoring position with timeOffset seek");
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
    _disposePlayerTimer?.cancel();
    _disposePlayerTimer = null;
    if (!_player.initialized ||
        _playbackStatus.value == PlaybackStatus.playing ||
        _playbackStatus.value == PlaybackStatus.loading) {
      return;
    }
    Log.debug("disposing player");
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
      "maxBitRate": _transcoding.$1 != TranscodingCodec.raw
          ? [_transcoding.$2.toString()]
          : [],
      if (!_subsonic.supports.timeOffsetMs)
        "timeOffset": offset != null ? [offset.inSeconds.toString()] : [],
      if (_subsonic.supports.timeOffsetMs)
        "timeOffsetMs": offset != null
            ? [offset.inMilliseconds.toString()]
            : [],
    }, _auth.con.auth);
    return Uri.parse(
      '${_auth.con.baseUri}/rest/stream${Uri(queryParameters: query)}',
    );
  }

  // ================ queue ================

  MediaQueue get queue => _queue;

  Future<void> changeQueue(MediaQueue queue) async {
    Log.trace("changing queue");
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
    Log.trace("restoring queue");
    final regular =
        (await _keyValue.loadObjectList(_queueSongsKey, Song.fromJson) ?? [])
            .toList();
    final priority = Queue<Song>.from(
      ((await _keyValue.loadObjectList(
            _priorityQueueSongsKey,
            Song.fromJson,
          )) ??
          []),
    );
    final index = await _keyValue.loadInt(_queueIndexKey);
    final looping = (await _keyValue.loadBool(_queueLoopingKey)) ?? false;

    final currentSong = await _keyValue.loadObject(
      _queueCurrentSongKey,
      Song.fromJson,
    );

    if (currentSong == null || index == null) {
      Log.debug("no queue to restore, initializing empty queue");
      _queue.setLoop(looping);
      await _clearPersistentQueueData();
      _restoredQueue = true;
      return;
    }

    Log.debug("restoring queue from database");
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
    _integration.updateMedia(
      currentSong,
      _subsonic.getCoverUri(currentSong.coverId, size: 512),
    );
  }

  Throttle? _persistQueueThrottle;
  void _persistQueue() async {
    if (!_restoredQueue) return;
    _persistQueueThrottle ??= Throttle(
      action: () async {
        if (_queue.current.value == null) {
          Log.trace(
            "clearing queue in database because current queue is empty",
          );
          await _clearPersistentQueueData();
          return;
        }
        Log.trace("storing current queue state in database");
        final looping = _queue.looping.value;
        await Future.wait([
          _keyValue.store(_queueSongsKey, _queue.regular.toList()),
          _keyValue.store(_priorityQueueSongsKey, _queue.priority.toList()),
          _keyValue.store(_queueLoopingKey, looping),
          _keyValue.store(_queueIndexKey, _queue.currentIndex),
          _keyValue.store(_queueCurrentSongKey, _queue.current.value),
        ]);
      },
      delay: const Duration(milliseconds: 500),
      leading: false,
      trailing: true,
    );
    _persistQueueThrottle?.call();
  }

  Future<void> _clearPersistentQueueData() async {
    await Future.wait([
      _keyValue.remove(_queueCurrentSongKey),
      _keyValue.remove(_queueSongsKey),
      _keyValue.remove(_priorityQueueSongsKey),
      _keyValue.remove(_queueIndexKey),
    ]);
  }

  Future<void> _enableAudioSession(bool enable) async {
    if (enable) {
      Log.debug("activating audio session");
    } else {
      Log.debug("deactivating audio session");
    }
    await _audioSession.setActive(enable);
  }

  // =============== dispose ===============
  Future<void> dispose() async {
    Log.trace("disposing audio handler");
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
