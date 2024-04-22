import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:crossonic/services/audio_player/audio_handler.dart';
import 'package:crossonic/services/audio_player/media_queue.dart';
import 'package:equatable/equatable.dart';

part 'now_playing_state.dart';

class NowPlayingCubit extends Cubit<NowPlayingState> {
  final CrossonicAudioHandler _audioHandler;
  late final StreamSubscription<CurrentMedia?> _currentMediaSubscription;
  late final StreamSubscription<CrossonicPlaybackState>
      _playbackStateSubscription;
  NowPlayingCubit(CrossonicAudioHandler audioHandler)
      : _audioHandler = audioHandler,
        super(const NowPlayingState(
            playbackState:
                CrossonicPlaybackState(status: CrossonicPlaybackStatus.idle))) {
    _currentMediaSubscription =
        _audioHandler.mediaQueue.current.listen((value) async {
      emit(state.copyWith(
          songID: value?.item.id ?? "",
          artist: value?.item.artist ?? "",
          songName: value?.item.title ?? "",
          album: value?.item.album ?? "",
          duration: value != null
              ? Duration(seconds: value.item.duration ?? 0)
              : Duration.zero,
          coverArtURL: value != null && value.item.coverArt != null
              ? (await _audioHandler.getCoverArtURL(value.item.coverArt!))
                  .toString()
              : ""));
    });
    _playbackStateSubscription =
        _audioHandler.crossonicPlaybackStatus.listen((value) {
      emit(state.copyWith(
        playbackState: value,
      ));
    });
  }

  @override
  Future<void> close() {
    _currentMediaSubscription.cancel();
    _playbackStateSubscription.cancel();
    return super.close();
  }
}
