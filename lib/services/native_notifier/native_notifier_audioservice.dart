import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:crossonic/repositories/api/models/media_model.dart';
import 'package:crossonic/services/audio_player/audio_handler.dart';
import 'package:crossonic/services/native_notifier/native_notifier.dart';

class NativeNotifierAudioService extends BaseAudioHandler
    with SeekHandler
    implements NativeNotifier {
  Future<void> Function()? _onPlay;
  Future<void> Function()? _onPause;
  Future<void> Function(Duration position)? _onSeek;
  Future<void> Function()? _onPlayNext;
  Future<void> Function()? _onPlayPrev;
  Future<void> Function()? _onStop;

  @override
  void ensureInitialized({
    required Future<void> Function() onPlay,
    required Future<void> Function() onPause,
    required Future<void> Function(Duration position) onSeek,
    required Future<void> Function() onPlayNext,
    required Future<void> Function() onPlayPrev,
    required Future<void> Function() onStop,
  }) {
    if (_onPlay != null) return;
    _onPlay = onPlay;
    _onPause = onPause;
    _onSeek = onSeek;
    _onPlayNext = onPlayNext;
    _onPlayPrev = onPlayPrev;
    _onStop = onStop;
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.pause,
        MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.skipToPrevious,
        MediaControl.stop,
      ],
      systemActions: {
        MediaAction.pause,
        MediaAction.play,
        MediaAction.playPause,
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
        MediaAction.stop,
      },
      androidCompactActionIndices: [0, 1],
    ));
  }

  @override
  Future<void> play() async {
    return _onPlay!();
  }

  @override
  Future<void> pause() async {
    await _onPause!();
  }

  @override
  Future<void> seek(Duration position) async {
    await _onSeek!(position);
  }

  @override
  Future<void> skipToNext() async {
    await _onPlayNext!();
  }

  @override
  Future<void> skipToPrevious() async {
    await _onPlayPrev!();
  }

  @override
  Future<void> stop() async {
    await _onStop!();
  }

  @override
  void updateMedia(Media? media, Uri? coverArt) {
    if (media == null) {
      mediaItem.add(null);
    } else {
      mediaItem.add(MediaItem(
        id: media.id,
        title: media.title,
        album: media.album,
        artUri: coverArt,
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
  void updatePlaybackState(CrossonicPlaybackStatus status) {
    switch (status) {
      case CrossonicPlaybackStatus.playing:
        playbackState.add(playbackState.value.copyWith(
            playing: true, processingState: AudioProcessingState.ready));
      case CrossonicPlaybackStatus.paused:
        playbackState.add(playbackState.value.copyWith(
            playing: false, processingState: AudioProcessingState.ready));
      case CrossonicPlaybackStatus.loading:
        playbackState.add(playbackState.value.copyWith(
            playing: false, processingState: AudioProcessingState.loading));
      case CrossonicPlaybackStatus.stopped:
        playbackState.add(playbackState.value.copyWith(
            playing: false, processingState: AudioProcessingState.idle));
    }
  }

  @override
  void updatePosition(Duration position,
      [Duration bufferedPosition = Duration.zero]) {
    playbackState.add(playbackState.value.copyWith(
      updatePosition: position,
      bufferedPosition: bufferedPosition,
    ));
  }
}
