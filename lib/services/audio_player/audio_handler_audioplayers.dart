import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:audioplayers/audioplayers.dart';
import 'package:crossonic/repositories/api/api.dart';
import 'package:crossonic/services/audio_player/audio_handler.dart';
import 'package:crossonic/services/audio_player/media_queue.dart';
import 'package:crossonic/services/native_notifier/native_notifier.dart';
import 'package:crossonic/widgets/cover_art.dart';
import 'package:rxdart/rxdart.dart';

class CrossonicAudioHandlerAudioPlayers implements CrossonicAudioHandler {
  final APIRepository _apiRepository;
  final NativeNotifier _notifier;
  final MediaQueue _queue = MediaQueue();
  final List<AudioPlayer> _players = [AudioPlayer(), AudioPlayer()];
  int _currentPlayer = 0;

  final BehaviorSubject<CrossonicPlaybackState> _playbackState =
      BehaviorSubject();

  String? _nextURL;
  String? _nextPlayerURL;
  var _playOnNextMediaChange = false;

  DateTime _lastPositionUpdate = DateTime.now();
  Timer? _positionTimer;

  CrossonicAudioHandlerAudioPlayers({
    required APIRepository apiRepository,
    required NativeNotifier notifier,
  })  : _apiRepository = apiRepository,
        _notifier = notifier {
    _playbackState.add(
        const CrossonicPlaybackState(status: CrossonicPlaybackStatus.stopped));

    apiRepository.authStatus.listen((status) async {
      if (status != AuthStatus.authenticated) {
        await stop();
      }
    });

    _notifier.ensureInitialized(
      onPause: pause,
      onPlay: play,
      onPlayNext: skipToNext,
      onPlayPrev: skipToPrevious,
      onSeek: seek,
      onStop: stop,
    );
    _notifier.updateMedia(null, null);

    CrossonicPlaybackStatus lastStatus = CrossonicPlaybackStatus.stopped;
    _playbackState.listen((value) {
      if (value.status == lastStatus) return;
      lastStatus = value.status;
      _notifier.updatePlaybackState(value.status);
      _updatePosition(value.position, true);
      switch (value.status) {
        case CrossonicPlaybackStatus.playing:
          _startPositionTimer();
        case CrossonicPlaybackStatus.paused:
          _stopPositionTimer();
        case CrossonicPlaybackStatus.stopped:
          _stopPositionTimer();
        default:
          break;
      }
    });

    for (var i = 0; i < _players.length; i++) {
      _players[i].onPlayerComplete.listen((_) async {
        if (i != _currentPlayer) {
          _players[i].pause();
          return;
        }

        if (mediaQueue.canAdvance) {
          await skipToNext();
        } else {
          await stop();
        }
      });
    }

    for (var i = 0; i < _players.length; i++) {
      int positionUpdateCount = 1;
      _players[i].onPositionChanged.listen((pos) {
        if (!kIsWeb && Platform.isLinux) {
          positionUpdateCount++;
        }
        if (i != _currentPlayer) {
          return;
        }
        _updatePosition(pos, positionUpdateCount % 5 == 0);
      });
      _players[i].onPlayerStateChanged.listen((state) {
        if (i != _currentPlayer) {
          return;
        }
        if (state == PlayerState.playing &&
            _playbackState.value.status != CrossonicPlaybackStatus.playing) {
          _playbackState.add(_playbackState.value
              .copyWith(status: CrossonicPlaybackStatus.playing));
        }
        if (state == PlayerState.paused &&
            _playbackState.value.status == CrossonicPlaybackStatus.playing) {
          _playbackState.add(_playbackState.value
              .copyWith(status: CrossonicPlaybackStatus.paused));
        }
      });
    }

    _queue.current.listen((value) async {
      CrossonicPlaybackStatus status = _playbackState.value.status;
      var playAfterChange = _playOnNextMediaChange;
      if (value?.currentChanged ?? false) {
        _notifier.updateMedia(
          value?.item,
          value?.item.coverArt != null
              ? await _apiRepository.getCoverArtURL(
                  coverArtID: value!.item.coverArt!,
                  size: const CoverResolution.large().size)
              : null,
        );
        _updatePosition(Duration.zero, true);
      }
      if (value == null) {
        _playOnNextMediaChange = false;
        if (status != CrossonicPlaybackStatus.stopped) {
          await stop();
        }
        return;
      }
      if (value.currentChanged) {
        _playOnNextMediaChange = false;

        _playbackState.add(const CrossonicPlaybackState(
            status: CrossonicPlaybackStatus.loading, position: Duration.zero));

        final streamURL =
            (await _apiRepository.getStreamURL(songID: value.item.id))
                .toString();

        final prefetched = value.fromNext &&
            _nextPlayerURL != null &&
            _nextPlayerURL == _nextURL;

        final oldPlayer = _currentPlayer;
        if (prefetched) {
          _currentPlayer = _nextPlayerIndex;
          _players[oldPlayer].release();
        } else {
          await _players[_currentPlayer].setSourceUrl(streamURL);
        }
        _nextPlayerURL = null;

        if (status == CrossonicPlaybackStatus.playing || playAfterChange) {
          await play();
        } else {
          _playbackState.add(const CrossonicPlaybackState(
              status: CrossonicPlaybackStatus.paused));
        }
      }
      if (value.next != null) {
        _nextURL = (await _apiRepository.getStreamURL(songID: value.next!.id))
            .toString();
      } else {
        _nextURL = null;
      }
    });
  }

  int get _nextPlayerIndex {
    var next = _currentPlayer + 1;
    if (next >= _players.length) {
      next = 0;
    }
    return next;
  }

  void _startPositionTimer() {
    if (_positionTimer != null) return;
    _positionTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (DateTime.now().difference(_lastPositionUpdate).inSeconds >= 2) {
        final pos = await _players[_currentPlayer].getCurrentPosition();
        if (pos != null) {
          _updatePosition(pos, !kIsWeb && Platform.isLinux);
        }
      }
    });
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  void _updatePosition(Duration pos, [bool updateNative = false]) async {
    _lastPositionUpdate = DateTime.now();
    _playbackState.add(
      _playbackState.value.copyWith(position: pos),
    );
    if (updateNative) {
      _notifier.updatePosition(pos);
    }
    if (_queue.current.value != null) {
      if (_queue.current.value!.item.duration != null &&
          _queue.current.value!.item.duration! - pos.inSeconds < 10) {
        if (_nextURL != null && _nextPlayerURL != _nextURL) {
          _nextPlayerURL = _nextURL;
          await _players[_nextPlayerIndex].setSourceUrl(_nextURL!);
        }
      }
    }
  }

  @override
  BehaviorSubject<CrossonicPlaybackState> get crossonicPlaybackStatus =>
      _playbackState;

  @override
  Future<void> playPause() async {
    if (!crossonicPlaybackStatus.hasValue) return;
    if (crossonicPlaybackStatus.value.status ==
        CrossonicPlaybackStatus.playing) {
      return await pause();
    }
    if (mediaQueue.current.valueOrNull == null) return;
    return await play();
  }

  @override
  Future<void> pause() async {
    if (_playbackState.value.status != CrossonicPlaybackStatus.playing) return;
    await _players[_currentPlayer].pause();
    _playbackState.add(
        _playbackState.value.copyWith(status: CrossonicPlaybackStatus.paused));
  }

  @override
  Future<void> play() async {
    if (_queue.current.value == null) return;
    await _players[_currentPlayer].resume();
    _playbackState.add(
        _playbackState.value.copyWith(status: CrossonicPlaybackStatus.playing));
  }

  @override
  Future<void> seek(Duration position) async {
    if (_playbackState.value.status == CrossonicPlaybackStatus.stopped ||
        _playbackState.value.status == CrossonicPlaybackStatus.loading) return;
    await _players[_currentPlayer].seek(position);
    _updatePosition(position, true);
  }

  @override
  Future<void> skipToNext() async {
    if (_queue.canAdvance) {
      playOnNextMediaChange();
      _queue.advance();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_playbackState.value.position.inSeconds > 3 || !_queue.canGoBack) {
      await seek(Duration.zero);
      return;
    }
    if (_queue.canGoBack) {
      playOnNextMediaChange();
      _queue.back();
    }
  }

  @override
  Future<void> stop() async {
    _playbackState.add(
        const CrossonicPlaybackState(status: CrossonicPlaybackStatus.stopped));
    _queue.clear();
    _nextURL = null;
    _nextPlayerURL = null;
    for (var i = 0; i < _players.length; i++) {
      await _players[i].release();
    }
  }

  @override
  MediaQueue get mediaQueue => _queue;

  @override
  Future<void> dispose() async {
    _stopPositionTimer();
    await stop();
    for (var i = 0; i < _players.length; i++) {
      await _players[i].dispose();
    }
  }

  @override
  void playOnNextMediaChange() {
    _playOnNextMediaChange = true;
  }
}
