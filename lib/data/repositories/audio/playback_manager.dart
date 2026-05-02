/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';
import 'dart:math';

import 'package:crossonic/data/repositories/audio/casting/device.dart';
import 'package:crossonic/data/repositories/audio/casting/device_manager.dart';
import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/data/repositories/audio/players/android_player.dart';
import 'package:crossonic/data/repositories/audio/queue/queue_manager.dart';
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/settings/replay_gain.dart';
import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:crossonic/data/repositories/settings/transcoding.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/data/services/media_integration/media_integration.dart';
import 'package:crossonic/data/services/methodchannel/method_channel_service.dart';
import 'package:flutter/foundation.dart';

class PlaybackManager {
  final AuthRepository _auth;
  final SettingsRepository _settings;
  final SubsonicRepository _subsonic;
  final MethodChannelService _methodChannel;

  final PlayerManager _player;

  PlayerManager get player => _player;

  final QueueManager _queue;

  QueueManager get queue => _queue;

  final DeviceManager _deviceManager;

  DeviceManager get deviceManager => _deviceManager;

  (TranscodingCodec, int) _transcoding;

  final MediaIntegration _integration;

  PlaybackManager({
    required QueueManager queueManager,
    required PlayerManager playerManager,
    required DeviceManager deviceManager,
    required AuthRepository authRepository,
    required SettingsRepository settingsRepository,
    required SubsonicRepository subsonicRepository,
    required MediaIntegration integration,
    required MethodChannelService methodChannel,
  }) : _queue = queueManager,
       _player = playerManager,
       _deviceManager = deviceManager,
       _auth = authRepository,
       _settings = settingsRepository,
       _subsonic = subsonicRepository,
       _transcoding = (
         settingsRepository.transcoding.codec,
         settingsRepository.transcoding.maxBitRate,
       ),
       _integration = integration,
       _methodChannel = methodChannel {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();

    _queue.currentAndNext.listen(_onCurrentOrNextChanged);

    _settings.transcoding.addListener(_onTranscodingChanged);
    _settings.replayGain.addListener(_applyReplayGain);

    _integration.ensureInitialized(
      onPlay: _player.play,
      onPause: _player.pause,
      onLoopChanged: _queue.setLoop,
      onPlayNext: playNext,
      onPlayPrev: playPrev,
      onSeek: _player.seek,
      onStop: _player.stop,
      onVolumeChanged: (volume) async => _player.volumeLinear = volume,
    );

    _queue.looping.listen((loop) {
      _integration.updateLoop(loop);
    });

    _queue.current.listen((current) {
      _applyReplayGain();
      _integration.updateMedia(
        current,
        current != null
            ? _subsonic.getCoverUri(
                current.coverId,
                constantSalt: true,
                size: 512,
              )
            : null,
      );
    });

    _player.advance.listen((_) async {
      await _queue.advance();
    });

    _player.positionUpdateStream.listen((pos) {
      _integration.updatePosition(pos);
    });

    PlaybackStatus previousPlaybackStatus = PlaybackStatus.stopped;
    _player.playbackStatus.listen((status) async {
      if (status == previousPlaybackStatus) return;
      previousPlaybackStatus = status;
      if (status == PlaybackStatus.stopped) {
        await _queue.clear();
      }
      _integration.updatePlaybackState(status);
    });

    _player.restartPlayback.listen(
      (pos) => _restartPlayback(
        pos,
        play: _player.playbackStatus.value == PlaybackStatus.playing,
      ),
    );
  }

  Future<void> changeDevice(Device device) async {
    final player = await deviceManager.createPlayerFromDevice(device);

    _player.cancelPlayerStreams();

    final play = _player.playbackStatus.value == PlaybackStatus.playing;
    final pos = _player.position;

    await _player.changePlayer(player);
    await _configurePlayerServerURL();

    final next = _queue.currentAndNext.value.next;
    await _player.setCurrent(_queue.current.value!, next: next, pos: pos);

    _player.connectPlayerStreams();

    Log.debug("player: $player");
    if (!kIsWeb && Platform.isAndroid) {
      if (player is AudioPlayerAndroid || player == null) {
        Log.debug("enabling android player");
        await _methodChannel.invokeMethod("setPlayerEnabled", {
          "enabled": true,
        });
      } else {
        Log.debug("disabling android player");
        await _methodChannel.invokeMethod("setPlayerEnabled", {
          "enabled": false,
        });
      }
    }

    if (play) {
      await _player.play();
    } else {
      await _player.pause();
    }
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
    if (_player.position.inSeconds > 3 || !_queue.canGoBack) {
      if (!_queue.canGoBack) {
        Log.trace(
          "seeking back to beginning of current song because there is no previous song",
        );
      } else {
        Log.trace(
          "seeking back to beginning of current song because the current position is >3 s into the song: ${_player.position.inSeconds}",
        );
      }
      await _player.seek(Duration.zero);
      return;
    }
    Log.trace("going back one song in the queue");
    await _queue.skipPrev();
  }

  Future<void> _onCurrentOrNextChanged(
    ({Song? current, Song? next, bool currentChanged, bool fromAdvance}) event,
  ) async {
    if (event.current == null) {
      Log.trace("current song changed to null, calling stop...");
      await _player.stop();
      return;
    }
    if (event.currentChanged) {
      Log.trace(
        "current song changed: ${event.current?.id}, from advance: ${event.fromAdvance}",
      );
    }

    if (event.currentChanged && !event.fromAdvance) {
      await _player.setCurrent(event.current!, next: event.next);
    } else {
      Log.trace("next song changed: ${event.next?.id}");
      await _player.setNext(event.next);
    }
  }

  bool? _wasAuthenticated;

  Future<void> _onAuthChanged() async {
    if (_auth.isAuthenticated) {
      if (_wasAuthenticated == false) {
        await _queue.init();
      }
      _wasAuthenticated = true;
      await _configurePlayerServerURL();
      return;
    }
    _wasAuthenticated = false;

    Log.debug("ensuring player is stopped because user logged out");
    await player.stop();

    await _configurePlayerServerURL();
  }

  Future<void> _onTranscodingChanged() async {
    if (!_auth.isAuthenticated) return;
    _transcoding = await _settings.transcoding.activeTranscoding();
    Log.debug(
      "current active transcoding profile: ${_transcoding.$1.name}${_transcoding.$1 != TranscodingCodec.raw ? "${_transcoding.$2} kbps" : ""}",
    );
    await _configurePlayerServerURL();
  }

  Future<void> _applyReplayGain() async {
    ReplayGainMode mode = _settings.replayGain.mode;
    final media = _queue.current.value;
    if (mode == ReplayGainMode.disabled || media == null) {
      await _player.applyReplayGain(1);
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

    double volume = pow(10, gain / 20) as double;
    Log.debug("replay gain of current song: $gain dB -> $volume");

    await _player.applyReplayGain(volume);
  }

  Future<void> _configurePlayerServerURL() async {
    if (_auth.isAuthenticated) {
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
    } else {
      await _player.configureServerURL(
        streamUri: Uri(),
        coverUri: Uri(),
        supportsTimeOffset: false,
        supportsTimeOffsetMs: false,
        maxBitRate: null,
        format: null,
      );
    }
  }

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
      await playNext();
      if (play) {
        await _player.play();
      }
      return;
    }

    final next = _queue.currentAndNext.value.next;
    await _player.setCurrent(_queue.current.value!, next: next, pos: pos);

    if (play) {
      await _player.play();
    } else {
      await _player.pause();
    }
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
}
