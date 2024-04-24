import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:crossonic/repositories/subsonic/subsonic.dart';
import 'package:crossonic/services/audio_player/audio_handler.dart';
import 'package:crossonic/services/audio_player/media_queue.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class CrossonicAudioHandlerJustAudio extends BaseAudioHandler
    with QueueHandler, SeekHandler
    implements CrossonicAudioHandler {
  final SubsonicRepository _subsonicRepository;
  final MediaQueue _queue = MediaQueue();
  late final AudioPlayer _player;
  ConcatenatingAudioSource? _playlist;
  int _lastIndex = 0;
  final BehaviorSubject<CrossonicPlaybackState> _crossonicPlaybackState =
      BehaviorSubject();
  Timer? _positionTimer;
  bool _playOnNextMediaChange = false;

  CrossonicAudioHandlerJustAudio({
    AudioPlayer? player,
    required SubsonicRepository subsonicRepository,
  }) : _subsonicRepository = subsonicRepository {
    _player = player ?? AudioPlayer();
    _crossonicPlaybackState.add(
        const CrossonicPlaybackState(status: CrossonicPlaybackStatus.idle));

    _player.playerStateStream.listen((event) async {
      if (event.playing) {
        _positionTimer ??=
            Timer.periodic(const Duration(milliseconds: 500), (timer) {
          _crossonicPlaybackState.add(_crossonicPlaybackState.value
              .copyWith(position: _player.position));
        });
      } else {
        _positionTimer?.cancel();
        _positionTimer = null;
      }

      if ((event.processingState == ProcessingState.idle ||
              event.processingState == ProcessingState.completed) &&
          _queue.current.value != null) {
        await stop();
      }

      _crossonicPlaybackState.add(CrossonicPlaybackState(
        status: switch (event.processingState) {
          ProcessingState.idle => CrossonicPlaybackStatus.idle,
          ProcessingState.completed => CrossonicPlaybackStatus.idle,
          ProcessingState.buffering => CrossonicPlaybackStatus.loading,
          ProcessingState.loading => CrossonicPlaybackStatus.loading,
          ProcessingState.ready => event.playing
              ? CrossonicPlaybackStatus.playing
              : CrossonicPlaybackStatus.paused,
        },
        position: _player.position,
      ));

      playbackState.add(playbackState.value.copyWith(
        playing: event.playing,
        processingState: switch (event.processingState) {
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.completed => AudioProcessingState.completed,
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.ready => AudioProcessingState.ready,
        },
        controls: [
          if (event.processingState != ProcessingState.idle)
            MediaControl.skipToPrevious,
          if (event.processingState == ProcessingState.ready) MediaControl.play,
          if (event.playing) MediaControl.pause,
          if (event.processingState != ProcessingState.idle) MediaControl.stop,
          if (event.processingState != ProcessingState.idle)
            MediaControl.skipToNext,
        ],
        systemActions: {
          if (event.processingState != ProcessingState.idle) MediaAction.seek,
          MediaAction.playPause,
          if (event.processingState == ProcessingState.ready) MediaAction.play,
          if (event.playing) MediaAction.pause,
          if (event.processingState != ProcessingState.idle &&
              _queue.canAdvance)
            MediaAction.skipToNext,
          if (event.processingState != ProcessingState.idle && _queue.canGoBack)
            MediaAction.skipToPrevious,
        },
      ));
    });

    _player.positionDiscontinuityStream.listen((_) => _updatePosition());

    _player.currentIndexStream.listen((index) {
      if (index == null || index <= _lastIndex) return;
      _lastIndex = index;
      _queue.advance();
    });

    _queue.current.listen((value) async {
      var playAfterChange = _playOnNextMediaChange;
      if (value == null) {
        _playOnNextMediaChange = false;
        await stop();
        return;
      }
      if (value.currentChanged) {
        _playOnNextMediaChange = false;
      } else if (_playlist != null) {
        _playlist!.removeAt(1);
        if (value.next != null) {
          _playlist!.add(AudioSource.uri(
              await _subsonicRepository.getStreamURL(songID: value.next!.id)));
        }
        return;
      }
      _updateMediaItem(value.item);
      if (value.fromNext &&
          _playlist != null &&
          _player.playerState.processingState != ProcessingState.completed &&
          _playlist!.length >= 2) {
        if (value.next == null) return;
        final nextURL =
            await _subsonicRepository.getStreamURL(songID: value.next!.id);
        _playlist!.add(AudioSource.uri(nextURL));
        return;
      }
      final playing = _player.playing;
      await _playlist?.clear();
      _lastIndex = 0;
      _playlist = ConcatenatingAudioSource(
        children: [
          AudioSource.uri(
              await _subsonicRepository.getStreamURL(songID: value.item.id)),
          if (value.next != null)
            AudioSource.uri(
                await _subsonicRepository.getStreamURL(songID: value.next!.id)),
        ],
      );
      await _player.setAudioSource(_playlist!);
      if (playing || playAfterChange) {
        await play();
      } else {
        _updatePosition();
      }
    });
  }

  void _updatePosition() {
    _crossonicPlaybackState.add(_crossonicPlaybackState.value.copyWith(
      position: _player.position,
    ));
    playbackState.add(playbackState.value.copyWith(
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
    ));
  }

  @override
  Future<void> play() async {
    await _player.play();
    _updatePosition();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _updatePosition();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _playlist?.clear();
    _playlist = null;
    _lastIndex = 0;
    await Future.delayed(const Duration(milliseconds: 200));
    _queue.clear();
    _updateMediaItem(null);
  }

  @override
  Future<void> seek(Duration position) async {
    return _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    if (_queue.canAdvance) {
      if (_player.hasNext) {
        await _player.seekToNext();
        await play();
      } else {
        playOnNextMediaChange();
        _queue.advance();
      }
      _updatePosition();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queue.canGoBack) {
      _queue.back();
      await play();
      _updatePosition();
    }
  }

  Future<void> _updateMediaItem(Media? media) async {
    if (media == null) {
      mediaItem.add(null);
    } else {
      mediaItem.add(MediaItem(
        id: media.id,
        title: media.title,
        album: media.album,
        artUri: media.coverArt != null
            ? await _subsonicRepository.getCoverArtURL(
                coverArtID: media.coverArt!, size: 500)
            : null,
        artist: media.artist,
        duration:
            media.duration != null ? Duration(seconds: media.duration!) : null,
        genre: media.genre,
        rating: media.userRating != null
            ? Rating.newStarRating(RatingStyle.range5stars, media.userRating!)
            : null,
        playable: true,
      ));
    }
  }

  @override
  MediaQueue get mediaQueue => _queue;

  @override
  Future<void> dispose() {
    return _player.dispose();
  }

  @override
  Future<void> playPause() {
    if (_player.playing) {
      return pause();
    }
    return play();
  }

  @override
  BehaviorSubject<CrossonicPlaybackState> get crossonicPlaybackStatus =>
      _crossonicPlaybackState;

  @override
  Future<Uri> getCoverArtURL(String id, [int? size]) async {
    return await _subsonicRepository.getCoverArtURL(coverArtID: id, size: size);
  }

  @override
  void playOnNextMediaChange() {
    _playOnNextMediaChange = true;
  }
}
