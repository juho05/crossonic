import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:crossonic/repositories/subsonic/subsonic.dart';
import 'package:crossonic/services/audio_player/media_queue.dart';
import 'package:just_audio/just_audio.dart';

class CrossonicAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final SubsonicRepository _subsonicRepository;
  final MediaQueue mediaQueue = MediaQueue();
  late final AudioPlayer _player;

  ConcatenatingAudioSource? _playlist;
  int _lastIndex = 0;

  CrossonicAudioHandler({
    AudioPlayer? player,
    required SubsonicRepository subsonicRepository,
  }) : _subsonicRepository = subsonicRepository {
    _player = player ?? AudioPlayer();

    _player.playerStateStream.listen((event) {
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
          if (event.processingState != ProcessingState.idle && !event.playing)
            MediaControl.stop,
          if (event.processingState != ProcessingState.idle)
            MediaControl.skipToNext,
        ],
        systemActions: {
          if (event.processingState != ProcessingState.idle) MediaAction.seek,
          MediaAction.playPause,
          if (event.processingState == ProcessingState.ready) MediaAction.play,
          if (event.playing) MediaAction.pause,
          if (event.processingState != ProcessingState.idle &&
              mediaQueue.canAdvance)
            MediaAction.skipToNext,
          if (event.processingState != ProcessingState.idle &&
              mediaQueue.canGoBack)
            MediaAction.skipToPrevious,
        },
      ));
    });

    _player.positionDiscontinuityStream.listen((event) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
      ));
    });

    _player.currentIndexStream.listen((index) {
      if (index == null || index <= _lastIndex) return;
      _lastIndex = index;
      mediaQueue.advance();
    });

    mediaQueue.current.listen((value) async {
      if (value == null) {
        if (mediaQueue.length > 0) {
          await _player.pause();
          mediaQueue.goto(0);
        } else {
          await _player.stop();
          _playlist?.clear();
          _playlist = null;
          _lastIndex = 0;
          _updateMediaItem(null);
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
      if (playing) {
        play();
      } else {
        playbackState.add(playbackState.value.copyWith(
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
        ));
      }
    });
  }

  @override
  Future<void> playFromUri(Uri uri, [Map<String, dynamic>? extras]) async {
    await _player.setUrl(uri.toString());
    if (Platform.isWindows) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    return play();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      return pause();
    }
    return play();
  }

  @override
  Future<void> play() async {
    await _player.play();
    playbackState.add(playbackState.value.copyWith(
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
    ));
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    playbackState.add(playbackState.value.copyWith(
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
    ));
  }

  @override
  Future<void> stop() async {
    mediaQueue.clear();
    return _player.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    return _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else {
      mediaQueue.advance();
    }
    playbackState.add(playbackState.value.copyWith(
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
    ));
  }

  @override
  Future<void> skipToPrevious() async {
    if (mediaQueue.canGoBack) {
      mediaQueue.back();
      playbackState.add(playbackState.value.copyWith(
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
      ));
    }
  }

  Future<void> _updateMediaItem(Media? media) async {
    if (media == null) {
      mediaItem.add(null);
    } else {
      print(media.title);
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

  Future<void> dispose() {
    return _player.dispose();
  }
}
