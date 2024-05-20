import 'dart:async';

import 'package:crossonic/repositories/api/api.dart';
import 'package:crossonic/services/audio_player/audio_handler.dart';
import 'package:crossonic/services/audio_player/media_queue.dart';
import 'package:crossonic/services/native_notifier/native_notifier.dart';
import 'package:crossonic/widgets/cover_art.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class CrossonicAudioHandlerJustAudio implements CrossonicAudioHandler {
  final APIRepository _apiRepository;
  final NativeNotifier _notifier;
  final MediaQueue _queue = MediaQueue();
  final AudioPlayer _player = AudioPlayer();
  ConcatenatingAudioSource? _playlist;
  int _currentPlayerPlaylistIndex = 0;

  Timer? _positionTimer;

  final BehaviorSubject<CrossonicPlaybackState> _playbackState =
      BehaviorSubject();

  bool _playOnNextMediaChange = false;

  CrossonicAudioHandlerJustAudio({
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
      onPlay: play,
      onPause: pause,
      onPlayNext: skipToNext,
      onPlayPrev: skipToPrevious,
      onSeek: seek,
      onStop: stop,
    );
    _notifier.updateMedia(null, null);

    CrossonicPlaybackStatus? previousPlaybackStatus;
    _playbackState.listen((value) {
      if (previousPlaybackStatus == value.status) return;
      previousPlaybackStatus = value.status;
      _notifier.updatePlaybackState(value.status);
      _updatePosition(updateNative: true);
      switch (value.status) {
        case CrossonicPlaybackStatus.playing:
          _startPositionTimer();
        case CrossonicPlaybackStatus.paused:
          _stopPositionTimer();
        case CrossonicPlaybackStatus.loading:
          break;
        case CrossonicPlaybackStatus.stopped:
          _stopPositionTimer();
      }
    });

    _player.playerStateStream.listen((event) async {
      if (event.processingState == ProcessingState.completed &&
          !_queue.canAdvance) {
        await stop();
        return;
      }
      if (event.processingState == ProcessingState.buffering ||
          event.processingState == ProcessingState.loading) {
        if (_playbackState.value.status != CrossonicPlaybackStatus.loading) {
          _playbackState.add(_playbackState.value
              .copyWith(status: CrossonicPlaybackStatus.loading));
        }
      } else if (event.playing) {
        if (_playbackState.value.status != CrossonicPlaybackStatus.playing) {
          _playbackState.add(_playbackState.value
              .copyWith(status: CrossonicPlaybackStatus.playing));
        }
      } else if (!event.playing && mediaQueue.current.value != null) {
        if (_playbackState.value.status != CrossonicPlaybackStatus.paused) {
          _playbackState.add(_playbackState.value
              .copyWith(status: CrossonicPlaybackStatus.paused));
        }
      } else {
        if (_playbackState.value.status != CrossonicPlaybackStatus.stopped) {
          await stop();
        }
      }
    });

    _player.currentIndexStream.listen((index) {
      if (index == null || index <= _currentPlayerPlaylistIndex) return;
      _currentPlayerPlaylistIndex = index;
      _queue.advance();
    });

    _player.positionDiscontinuityStream.listen((_) {
      _updatePosition();
    });

    _queue.current.listen((value) async {
      CrossonicPlaybackStatus status = _playbackState.value.status;
      var playAfterChange = _playOnNextMediaChange;

      if (value?.currentChanged ?? false) {
        _updateMediaItem(value?.item);
        _updatePosition(
            position: Duration.zero,
            bufferedPosition: Duration.zero,
            updateNative: true);
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
        final streamURL =
            await _apiRepository.getStreamURL(songID: value.item.id);
        if (!value.fromNext || _playlist == null) {
          _playbackState.add(const CrossonicPlaybackState(
              status: CrossonicPlaybackStatus.loading,
              position: Duration.zero));
          _playlist?.clear();
          _currentPlayerPlaylistIndex = 0;
          _playlist =
              ConcatenatingAudioSource(children: [AudioSource.uri(streamURL)]);
          await _player.setAudioSource(_playlist!);
        }
        if (status == CrossonicPlaybackStatus.playing || playAfterChange) {
          await play();
        } else {
          _playbackState.add(const CrossonicPlaybackState(
              status: CrossonicPlaybackStatus.paused));
        }
      }
      if (_currentPlayerPlaylistIndex + 1 < _playlist!.length) {
        _playlist!.removeAt(_currentPlayerPlaylistIndex + 1);
      }
      if (value.next != null) {
        _playlist!.add(AudioSource.uri(
            await _apiRepository.getStreamURL(songID: value.next!.id)));
      }
    });
  }

  void _startPositionTimer() {
    if (_positionTimer != null) return;
    int count = -1;
    _positionTimer =
        Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      count = (count + 1) % 15;
      _updatePosition(updateNative: count == 0 && _queue.current.value != null);
    });
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  void _updatePosition(
      {Duration? position,
      Duration? bufferedPosition,
      bool updateNative = true}) {
    position ??= _player.position;
    bufferedPosition ??= _player.bufferedPosition;
    _playbackState.add(_playbackState.value.copyWith(
      position: position,
      bufferedPosition: bufferedPosition,
    ));
    if (updateNative) {
      _notifier.updatePosition(position, bufferedPosition);
    }
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
  Future<void> pause() async {
    if (_playbackState.value.status != CrossonicPlaybackStatus.playing) return;
    await _player.pause();
    _updatePosition();
  }

  @override
  Future<void> play() async {
    if (_queue.current.value == null) return;
    _player.play();
    _updatePosition();
  }

  @override
  Future<void> seek(Duration position) async {
    if (_playbackState.value.status == CrossonicPlaybackStatus.stopped ||
        _playbackState.value.status == CrossonicPlaybackStatus.loading) return;
    await _player.seek(position);
    _updatePosition(position: position, updateNative: true);
  }

  @override
  Future<void> skipToNext() async {
    if (_queue.canAdvance) {
      if (_player.hasNext) {
        await _player.seekToNext();
        play();
      } else {
        playOnNextMediaChange();
        _queue.advance();
      }
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
    _updateMediaItem(null);
    await _player.stop();
    _playlist?.clear();
    _playlist = null;
    _currentPlayerPlaylistIndex = 0;
  }

  Future<void> _updateMediaItem(Media? media) async {
    _notifier.updateMedia(
        media,
        media?.coverArt != null
            ? await _apiRepository.getCoverArtURL(
                coverArtID: media!.coverArt!,
                size: const CoverResolution.large().size)
            : null);
  }

  @override
  MediaQueue get mediaQueue => _queue;

  @override
  Future<void> dispose() async {
    _stopPositionTimer();
    await stop();
    await _player.dispose();
  }

  @override
  BehaviorSubject<CrossonicPlaybackState> get crossonicPlaybackStatus =>
      _playbackState;

  @override
  void playOnNextMediaChange() {
    _playOnNextMediaChange = true;
  }
}
