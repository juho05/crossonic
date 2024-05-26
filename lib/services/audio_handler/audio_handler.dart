import 'dart:async';
import 'dart:io';

import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:crossonic/services/audio_handler/players/player.dart';
import 'package:crossonic/services/audio_handler/media_queue.dart';
import 'package:crossonic/services/audio_handler/notifiers/notifier.dart';
import 'package:crossonic/widgets/cover_art.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

enum CrossonicPlaybackStatus {
  stopped,
  loading,
  playing,
  paused,
}

class CrossonicPlaybackState extends Equatable {
  final CrossonicPlaybackStatus status;
  final Duration position;
  final Duration bufferedPosition;

  const CrossonicPlaybackState({
    required this.status,
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
  });

  CrossonicPlaybackState copyWith({
    CrossonicPlaybackStatus? status,
    Duration? position,
    Duration? bufferedPosition,
  }) =>
      CrossonicPlaybackState(
        status: status ?? this.status,
        position: position ?? this.position,
        bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      );

  @override
  List<Object?> get props => [status, position, bufferedPosition];
}

class CrossonicAudioHandler {
  final MediaQueue _queue = MediaQueue();
  MediaQueue get mediaQueue => _queue;
  final BehaviorSubject<CrossonicPlaybackState> _playbackState =
      BehaviorSubject.seeded(const CrossonicPlaybackState(
          status: CrossonicPlaybackStatus.stopped));
  BehaviorSubject<CrossonicPlaybackState> get crossonicPlaybackStatus =>
      _playbackState;

  final CrossonicAudioPlayer _player;
  final APIRepository _apiRepository;
  final NativeNotifier _notifier;

  bool _playOnNextMediaChange = false;
  Timer? _positionTimer;

  bool _isRaw = false;
  bool _nextIsRaw = false;
  Duration _positionOffset = Duration.zero;

  CrossonicAudioHandler({
    required APIRepository apiRepository,
    required CrossonicAudioPlayer player,
    required NativeNotifier notifier,
  })  : _apiRepository = apiRepository,
        _player = player,
        _notifier = notifier {
    _apiRepository.authStatus.listen((status) async {
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

    _queue.current.listen(_mediaChanged);

    _player.eventStream.listen((event) {
      if (event == AudioPlayerEvent.advance) {
        _queue.advance();
        return;
      }
      var status = switch (event) {
        AudioPlayerEvent.stopped => CrossonicPlaybackStatus.stopped,
        AudioPlayerEvent.loading => CrossonicPlaybackStatus.loading,
        AudioPlayerEvent.playing => CrossonicPlaybackStatus.playing,
        AudioPlayerEvent.paused => CrossonicPlaybackStatus.paused,
        AudioPlayerEvent.advance => throw Exception("should never happen"),
      };
      if (_queue.length == 0) {
        status = CrossonicPlaybackStatus.stopped;
      }
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
  }

  Future<void> _mediaChanged(CurrentMedia? media) async {
    CrossonicPlaybackStatus status = _playbackState.value.status;
    var playAfterChange = _playOnNextMediaChange;
    if (media?.currentChanged ?? false) {
      _notifier.updateMedia(
        media?.item,
        media?.item.coverArt != null
            ? await _apiRepository.getCoverArtURL(
                coverArtID: media!.item.coverArt!,
                size: const CoverResolution.large().size)
            : null,
      );
    }
    if (media == null) {
      _playOnNextMediaChange = false;
      if (status != CrossonicPlaybackStatus.stopped) {
        await stop();
      }
      return;
    }

    if (media.currentChanged) {
      _playOnNextMediaChange = false;
      if (!media.fromNext) {
        await _player.setCurrent(media.item,
            await _apiRepository.getStreamURL(songID: media.item.id));
        // update _isRaw
      } else {
        _isRaw = _nextIsRaw;
      }
      _positionOffset = Duration.zero;
      if (status == CrossonicPlaybackStatus.playing || playAfterChange) {
        await play();
      } else {
        await pause();
      }
    }

    _updatePosition(true);

    if (media.next != null) {
      await _player.setNext(media.next,
          await _apiRepository.getStreamURL(songID: media.next!.id));
      // TODO update _nextIsRaw
    } else {
      await _player.setNext(null, null);
    }
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
    final pos = await _player.position;
    final bufferedPos = await _player.bufferedPosition;
    _playbackState.add(_playbackState.value.copyWith(
      position: pos + _positionOffset,
      bufferedPosition: bufferedPos + _positionOffset,
    ));
    if (updateNative) {
      _notifier.updatePosition(
          pos + _positionOffset, bufferedPos + _positionOffset);
    }
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  Future<void> playPause() async {
    if (!crossonicPlaybackStatus.hasValue) return;
    if (crossonicPlaybackStatus.value.status ==
        CrossonicPlaybackStatus.playing) {
      return await pause();
    }
    if (mediaQueue.current.valueOrNull == null) return;
    return await play();
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    _playbackState.add(
        const CrossonicPlaybackState(status: CrossonicPlaybackStatus.stopped));
    await _player.stop();
    _queue.clear();
  }

  Future<void> seek(Duration position) async {
    final media = _queue.current.valueOrNull?.item;
    if (media == null) return;
    if (_isRaw) {
      await _player.seek(position);
    } else {
      position = Duration(seconds: position.inSeconds);
      await _player.setCurrent(
          media,
          await _apiRepository.getStreamURL(
              songID: media.id, timeOffset: position.inSeconds));
      _positionOffset = position;
      // update _isRaw
      await play();
    }
    _playbackState.add(_playbackState.value.copyWith(position: position));
  }

  Future<void> skipToNext() async {
    if (_queue.canAdvance) {
      playOnNextMediaChange();
      _queue.advance(false);
    }
  }

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

  Future<void> dispose() async {
    await _player.dispose();
  }

  void playOnNextMediaChange() {
    _playOnNextMediaChange = true;
  }
}
