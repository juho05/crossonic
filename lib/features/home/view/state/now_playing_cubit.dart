import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:bloc/bloc.dart';
import 'package:crossonic/services/audio_player/audio_handler.dart';
import 'package:equatable/equatable.dart';

part 'now_playing_state.dart';

class NowPlayingCubit extends Cubit<NowPlayingState> {
  final CrossonicAudioHandler _audioHandler;
  late final StreamSubscription<MediaItem?> _mediaItemSubscription;
  late final StreamSubscription<PlaybackState> _playbackStateSubscription;
  Timer? _positionTimer;
  NowPlayingCubit(CrossonicAudioHandler audioHandler)
      : _audioHandler = audioHandler,
        super(const NowPlayingState(playing: true)) {
    _mediaItemSubscription = _audioHandler.mediaItem.listen((value) {
      emit(state.copyWith(
        songID: value?.id ?? "",
        artist: value?.artist ?? "",
        songName: value?.displayTitle ?? (value?.title ?? ""),
      ));
    });
    _playbackStateSubscription = _audioHandler.playbackState.listen((value) {
      _setPositionTimerActive(value.playing);
      emit(state.copyWith(
        playing: value.playing,
        position: value.position,
      ));
    });
  }

  void _setPositionTimerActive(bool active) {
    if (!active && _positionTimer == null || active && _positionTimer != null) {
      return;
    }
    if (active) {
      _positionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        emit(state.copyWith(
          position: _audioHandler.playbackState.value.position,
        ));
      });
    } else {
      _positionTimer?.cancel();
      _positionTimer = null;
    }
  }

  @override
  Future<void> close() {
    _mediaItemSubscription.cancel();
    _playbackStateSubscription.cancel();
    return super.close();
  }
}
