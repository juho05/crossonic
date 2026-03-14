import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:crossonic/data/repositories/audio/players/android_player.dart';
import 'package:crossonic/data/repositories/audio/players/mediakit_player.dart';
import 'package:crossonic/data/repositories/audio/players/player.dart';
import 'package:crossonic/data/repositories/audio/queue/db_queue.dart';
import 'package:crossonic/data/repositories/audio/queue/media_queue.dart';
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/cover/cover_repository.dart';
import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
import 'package:crossonic/data/repositories/settings/replay_gain.dart';
import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:crossonic/data/repositories/settings/transcoding.dart';
import 'package:crossonic/data/repositories/song/song_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/data/services/database/database.dart';
import 'package:crossonic/data/services/media_integration/media_integration.dart';
import 'package:crossonic/data/services/methodchannel/method_channel_service.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

enum PlaybackStatus { stopped, loading, playing, paused }

class AudioHandler {
  final AuthRepository _auth;
  final SubsonicRepository _subsonic;
  final SettingsRepository _settings;
  final KeyValueRepository _keyValue;

  late final AudioPlayer _player;
  StreamSubscription? _playerEventSubscription;

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

  final BehaviorSubject<Duration> _positionUpdateStream =
      BehaviorSubject.seeded(Duration.zero);
  ValueStream<Duration> get positionUpdateStream =>
      _positionUpdateStream.stream;

  Future<Duration> get bufferedPosition async => await _player.bufferedPosition;

  final DbQueue _queue;
  StreamSubscription? _queueCurrentSubscription;

  bool _playOnNextMediaChange = false;

  (TranscodingCodec, int) _transcoding;

  double _volume = 1;

  final BehaviorSubject<double> _volumeLinearStream = BehaviorSubject.seeded(1);
  ValueStream<double> get volumeLinearStream => _volumeLinearStream.stream;

  double get volumeLinear => _volume;
  set volumeLinear(double volume) {
    _volume = volume;
    _applyReplayGain();
    _volumeLinearStream.add(_volume);
    _integration.updateVolume(volumeCubic);
  }

  double get volumeCubic => _volumeToCubic(_volume);
  set volumeCubic(double volume) {
    volumeLinear = _volumeToLinear(volume);
  }

  AudioHandler({
    required MethodChannelService methodChannel,
    required MediaIntegration integration,
    required CoverRepository coverRepository,
    required AuthRepository authRepository,
    required SubsonicRepository subsonicRepository,
    required SettingsRepository settingsRepository,
    required SongDownloader songDownloader,
    required KeyValueRepository keyValueRepository,
    required Database database,
    required SongRepository songRepository,
  }) : _integration = integration,
       _auth = authRepository,
       _subsonic = subsonicRepository,
       _settings = settingsRepository,
       _transcoding = (
         settingsRepository.transcoding.codec,
         settingsRepository.transcoding.maxBitRate,
       ),
       _keyValue = keyValueRepository,
       _queue = DbQueue(
         db: database,
         keyValue: keyValueRepository,
         songRepo: songRepository,
       ) {
    // TODO remove in v0.5.0
    // remove old queue store
    _removeOldQueueStore();

    if (!kIsWeb && Platform.isAndroid) {
      _player = AudioPlayerAndroid(
        methodChannel: methodChannel,
        settings: settingsRepository,
        coverRepository: coverRepository,
        downloader: songDownloader,
        playNextHandler: playNext,
        playPrevHandler: playPrev,
        setVolumeHandler: (volume) async => volumeLinear = volume,
        setLoopHandler: (loop) async => await _queue.setLoop(loop),
        setQueueHandler: (songs) async {
          playOnNextMediaChange();
          await _queue.replace(songs);
        },
        restartPlayback: () async {
          await _restartPlayback(
            position,
            play: playbackStatus.value == PlaybackStatus.playing,
          );
        },
      );
    } else {
      _player = AudioPlayerMediaKit(
        downloader: songDownloader,
        settings: settingsRepository,
        integration: integration,
        playNextHandler: playNext,
        playPrevHandler: playPrev,
        setLoopHandler: (loop) async => await _queue.setLoop(loop),
        setQueueHandler: (songs) async {
          playOnNextMediaChange();
          await _queue.replace(songs);
        },
        setVolumeHandler: (volume) async => volumeLinear = volume,
      );
    }
    _player
        .init(
          streamUri: _createStreamUri(),
          coverUri: _createCoverUri(),
          supportsTimeOffset: _subsonic.supports.transcodeOffset,
          supportsTimeOffsetMs: _subsonic.supports.timeOffsetMs,
          format: _transcoding.$1 != TranscodingCodec.serverDefault
              ? _transcoding.$1.name
              : null,
          maxBitRate: _transcoding.$1 != TranscodingCodec.raw
              ? _transcoding.$2
              : null,
        )
        .then((value) async {
          _auth.addListener(_authChanged);

          _player.positionDiscontinuity.listen((pos) {
            _updatePosition(pos);
          });

          _queueCurrentSubscription = _queue.currentAndNext.listen(
            _onCurrentOrNextChanged,
          );

          _playerEventSubscription = _player.eventStream.listen(_playerEvent);

          _settings.replayGain.addListener(_onReplayGainChanged);
          _settings.transcoding.addListener(_onTranscodingChanged);
          _onTranscodingChanged();

          _queue.looping.listen((loop) {
            _integration.updateLoop(loop);
          });
        });

    _queue.init();
  }

  // ================ playback controls ================

  void playOnNextMediaChange() {
    _playOnNextMediaChange = true;
    Log.trace("enabling playOnNextMediaChange");
  }

  Future<void> play() async {
    Log.trace("play");

    if (_playbackStatus.value == PlaybackStatus.playing) {
      return;
    }

    await _updatePlayerVolume();

    await _player.play();
  }

  Future<void> pause() async {
    Log.trace("pause");

    if (_playbackStatus.value == PlaybackStatus.paused) {
      return;
    }
    await _player.pause();
    _updatePlayerVolume();
  }

  Future<void> stop() async {
    Log.trace("stop");
    _playOnNextMediaChange = false;
    _integration.updatePosition(Duration.zero);
    _playbackStatus.add(PlaybackStatus.stopped);
    _updatePosition(Duration.zero);
    await _queue.clear();
    await _player.stop();
  }

  Duration? _seekingPos;

  Future<void> seek(Duration pos) async {
    Log.trace("seek to $pos");
    _seekingPos = pos;
    _updatePosition();
    await _player.seek(pos);
    _seekingPos = null;
  }

  Future<void> _updatePosition([Duration? pos]) async {
    if (_seekingPos != null) {
      pos = _seekingPos;
    }
    pos ??= await _player.position;
    Log.trace("updating current position: $pos");
    _positionUpdate = (DateTime.now(), pos);
    _integration.updatePosition(pos);
    _positionUpdateStream.add(position);
  }

  Future<void> playNext() async {
    Log.trace("play next");
    if (!_queue.canAdvance) {
      Log.warn("ignoring play next request because there is not next song");
      return;
    }
    await _queue.skipNext();
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
    await _queue.skipPrev();
  }

  // ================ callbacks ================

  AudioPlayerEvent? _previousAudioPlayerEvent;
  Future<void> _playerEvent(AudioPlayerEvent event) async {
    Log.trace("player event received: ${event.name}");
    if (event == AudioPlayerEvent.advance) {
      await _updatePosition(Duration.zero);
      await _queue.advance();
      return;
    }

    if (_previousAudioPlayerEvent == event) return;

    Duration lastPos = _seekingPos ?? _positionUpdate.$2;
    if (_previousAudioPlayerEvent == AudioPlayerEvent.playing) {
      lastPos += DateTime.now().difference(_positionUpdate.$1);
    }

    _previousAudioPlayerEvent = event;

    var status = switch (event) {
      AudioPlayerEvent.stopped => PlaybackStatus.stopped,
      AudioPlayerEvent.loading => PlaybackStatus.loading,
      AudioPlayerEvent.playing => PlaybackStatus.playing,
      AudioPlayerEvent.paused => PlaybackStatus.paused,
      AudioPlayerEvent.advance => throw Exception("should never happen"),
    };

    Log.debug("new player status: $status");

    if (status == PlaybackStatus.stopped || _queue.current.value == null) {
      await stop();
      return;
    }

    _playbackStatus.add(status);

    if (status == PlaybackStatus.playing) {
      _updatePosition();
    } else {
      _updatePosition(lastPos);
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
    if (event.currentChanged) {
      Log.trace(
        "current song changed: ${event.current?.id}, from advance: ${event.fromAdvance}",
      );
      await _updatePosition(Duration.zero);
      await _applyReplayGain();
    }

    if (event.currentChanged && !event.fromAdvance) {
      await _player.setCurrent(event.current!, next: event.next);
      if (playAfterChange) {
        await play();
      }
    } else {
      Log.trace("next song changed: ${event.next?.id}");
      await _player.setNext(event.next);
    }
  }

  Future<void> _authChanged() async {
    if (_auth.isAuthenticated) {
      await _player.configureServerURL(
        streamUri: _createStreamUri(),
        coverUri: _createCoverUri(),
        supportsTimeOffset: _subsonic.supports.transcodeOffset,
        supportsTimeOffsetMs: _subsonic.supports.timeOffsetMs,
        updateCurrentMediaItem: true,
        maxBitRate: _transcoding.$1 != TranscodingCodec.raw
            ? _transcoding.$2
            : null,
        format: _transcoding.$1 != TranscodingCodec.serverDefault
            ? _transcoding.$1.name
            : null,
      );
      return;
    }
    if (playbackStatus.value != PlaybackStatus.stopped) {
      Log.debug("stopping playback because user logged out");
      await stop();
    }
    await _player.configureServerURL(
      streamUri: Uri(),
      coverUri: Uri(),
      supportsTimeOffset: false,
      supportsTimeOffsetMs: false,
      maxBitRate: null,
      format: null,
    );
  }

  Future<void> _onReplayGainChanged() async {
    await _applyReplayGain();
  }

  Future<void> _onTranscodingChanged() async {
    _transcoding = await _settings.transcoding.activeTranscoding();
    Log.debug(
      "current active transcoding profile: ${_transcoding.$1.name}${_transcoding.$1 != TranscodingCodec.raw ? "${_transcoding.$2} kbps" : ""}",
    );
    await _player.configureServerURL(
      streamUri: _createStreamUri(),
      coverUri: _createCoverUri(),
      supportsTimeOffset: _subsonic.supports.transcodeOffset,
      supportsTimeOffsetMs: _subsonic.supports.timeOffsetMs,
      format: _transcoding.$1 != TranscodingCodec.serverDefault
          ? _transcoding.$1.name
          : null,
      maxBitRate: _transcoding.$1 != TranscodingCodec.raw
          ? _transcoding.$2
          : null,
      updateCurrentMediaItem: false,
    );
  }

  // ================ helpers ================

  Future<void> _restartPlayback(Duration pos, {bool play = true}) async {
    if (_queue.current.value == null) return;
    Log.debug(
      "Restarting playback at position $pos, play after restore: $play",
    );

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

    final next = _queue.currentAndNext.value.next;
    await _player.setCurrent(_queue.current.value!, next: next, pos: pos);
    _seekingPos = null;

    if (play) {
      await this.play();
    } else {
      await pause();
    }
  }

  double _replayGainVolume = 1;
  Future<void> _applyReplayGain() async {
    ReplayGainMode mode = _settings.replayGain.mode;
    final media = _queue.current.value;
    if (mode == ReplayGainMode.disabled || media == null) {
      _replayGainVolume = 1;
      await _updatePlayerVolume();
      return;
    }

    Log.trace("applying replay gain, mode: ${mode.name}");

    double gain = _settings.replayGain.fallbackGain;

    if (mode == ReplayGainMode.auto) {
      mode = ReplayGainMode.track;

      if (media.album != null) {
        bool previousIsSameAlbum = true;
        if (_queue.currentIndex > 0) {
          final previous = (await _queue.getRegularSongs(
            limit: 1,
            offset: _queue.currentIndex - 1,
          )).first;
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
    _replayGainVolume = volume;
    await _updatePlayerVolume();
  }

  Future<void> _updatePlayerVolume({double scalar = 1}) async {
    double volume = _volume * scalar;
    volume *= _replayGainVolume;
    await _player.setVolume(volume);
  }

  Uri _createStreamUri() {
    if (!_auth.isAuthenticated) return Uri();
    return Uri.parse(
      '${_auth.con.baseUri}/rest/stream${Uri(queryParameters: _subsonic.generateQuery(const {}, _auth.con.auth))}',
    );
  }

  Uri _createCoverUri() {
    if (!_auth.isAuthenticated) return Uri();
    return Uri.parse(
      '${_auth.con.baseUri}/rest/getCoverArt${Uri(queryParameters: _subsonic.generateQuery(const {}, _auth.con.auth))}',
    );
  }

  // ================ queue ================

  MediaQueue get queue => _queue;

  Future<void> _removeOldQueueStore() async {
    const String queueCurrentSongKey = "queue_state.current_song";
    const String queueSongsKey = "queue_state.regular.songs";
    const String priorityQueueSongsKey = "queue_state.priority.songs";
    const String queueIndexKey = "queue_state.index";
    const String queueLoopingKey = "queue_state.looping";

    await _keyValue.remove(queueCurrentSongKey);
    await _keyValue.remove(queueSongsKey);
    await _keyValue.remove(priorityQueueSongsKey);
    await _keyValue.remove(queueIndexKey);
    await _keyValue.remove(queueLoopingKey);
  }

  double _volumeToLinear(double volume) {
    return pow(volume, 3) as double;
  }

  double _volumeToCubic(double volume) {
    return pow(volume, 1 / 3.0) as double;
  }

  // =============== dispose ===============
  Future<void> dispose() async {
    Log.trace("disposing audio handler");
    await stop();
    // dispose queue
    await _queueCurrentSubscription?.cancel();
    _queue.dispose();

    // dispose player
    await _playerEventSubscription?.cancel();
    await _player.dispose();

    _settings.replayGain.removeListener(_onReplayGainChanged);
    _settings.transcoding.removeListener(_onTranscodingChanged);
    _auth.removeListener(_authChanged);
  }
}
