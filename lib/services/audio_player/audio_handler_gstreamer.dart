import 'dart:async';
import 'dart:io';

import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:crossonic/services/audio_player/audio_handler.dart';
import 'package:crossonic/services/audio_player/media_queue.dart';
import 'package:crossonic/services/native_notifier/native_notifier.dart';
import 'package:crossonic/widgets/cover_art.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/src/subjects/behavior_subject.dart';

class CrossonicAudioHandlerGstreamer implements CrossonicAudioHandler {
  static const _methodChan =
      MethodChannel("crossonic.julianh.de/gstreamer/method");
  static const _eventChan =
      EventChannel("crossonic.julianh.de/gstreamer/event");

  final APIRepository _apiRepository;
  final NativeNotifier _notifier;
  final MediaQueue _queue = MediaQueue();
  final BehaviorSubject<CrossonicPlaybackState> _playbackState =
      BehaviorSubject();
  var _playOnNextMediaChange = false;

  Timer? _positionTimer;

  CrossonicAudioHandlerGstreamer(
      {required APIRepository apiRepository, required NativeNotifier notifier})
      : _apiRepository = apiRepository,
        _notifier = notifier {
    _playbackState.add(
        const CrossonicPlaybackState(status: CrossonicPlaybackStatus.stopped));

    apiRepository.authStatus.listen((status) async {
      if (status != AuthStatus.authenticated) {
        await stop();
      }
    });

    _eventChan.receiveBroadcastStream().listen((event) {
      final statusStr = event as String;
      if (statusStr == "advance") {
        _queue.advance();
        return;
      }
      final status = CrossonicPlaybackStatus.values.byName(statusStr);
      if (status != _playbackState.value.status) {
        if (status == CrossonicPlaybackStatus.stopped) {
          stop();
        } else {
          _notifier.updatePlaybackState(status);
          _playbackState.add(_playbackState.value.copyWith(
            status: status,
          ));
          _updatePosition(true);
          if (status == CrossonicPlaybackStatus.playing) {
            _startPositionTimer();
          } else {
            _stopPositionTimer();
          }
        }
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
        if (!value.fromNext) {
          _methodChan.invokeMethod("setCurrent", {
            "url": (await _apiRepository.getStreamURL(songID: value.item.id))
                .toString()
          });
        }
        if (status == CrossonicPlaybackStatus.playing || playAfterChange) {
          await play();
        } else {
          await pause();
        }
      }

      _updatePosition(true);

      if (value.next != null) {
        _methodChan.invokeMethod("setNext", {
          "url": (await _apiRepository.getStreamURL(songID: value.next!.id))
              .toString()
        });
      } else {
        _methodChan.invokeMethod("setNext", {
          "url": null,
        });
      }
    });
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
    if (_playbackState.value.status == CrossonicPlaybackStatus.stopped) {
      _playbackState.add(_playbackState.value.copyWith(
        position: Duration.zero,
      ));
      if (updateNative) {
        _notifier.updatePosition(Duration.zero);
      }
      return;
    }
    if (_playbackState.value.status != CrossonicPlaybackStatus.playing &&
        _playbackState.value.status != CrossonicPlaybackStatus.paused) return;
    final pos = Duration(
        milliseconds: await _methodChan.invokeMethod<int>("getPosition") ?? 0);
    _playbackState.add(_playbackState.value.copyWith(
      position: pos,
    ));
    if (updateNative) {
      _notifier.updatePosition(pos);
    }
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  @override
  BehaviorSubject<CrossonicPlaybackState> get crossonicPlaybackStatus =>
      _playbackState;

  @override
  Future<void> dispose() async {
    await stop();
  }

  @override
  MediaQueue get mediaQueue => _queue;

  @override
  Future<void> pause() async {
    await _methodChan.invokeMethod("pause");
  }

  @override
  Future<void> play() async {
    await _methodChan.invokeMethod("play");
  }

  @override
  void playOnNextMediaChange() {
    _playOnNextMediaChange = true;
  }

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
  Future<void> seek(Duration position) async {
    await _methodChan
        .invokeListMethod("seek", {"position": position.inMilliseconds});
    _playbackState.add(_playbackState.value.copyWith(position: position));
  }

  @override
  Future<void> skipToNext() async {
    if (_queue.canAdvance) {
      playOnNextMediaChange();
      _queue.advance(false);
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
    _stopPositionTimer();
    _playbackState.add(
        const CrossonicPlaybackState(status: CrossonicPlaybackStatus.stopped));
    _queue.clear();
  }
}
