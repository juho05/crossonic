import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:crossonic/services/audio_handler/audio_handler.dart';
import 'package:crossonic/services/audio_handler/media_queue.dart';
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
            playbackState: CrossonicPlaybackState(
                status: CrossonicPlaybackStatus.stopped))) {
    _currentMediaSubscription =
        _audioHandler.mediaQueue.current.listen((value) {
      emit(
        state.copyWith(
          songID: value?.item.id ?? "",
          artists: value != null
              ? APIRepository.getArtistsOfSong(value.item)
              : const Artists(artists: [], displayName: ""),
          songName: value?.item.title ?? "",
          album: value?.item.album ?? "Unknown album",
          albumID: value?.item.albumId,
          duration: value != null
              ? Duration(seconds: value.item.duration ?? 0)
              : Duration.zero,
          coverArtID: value?.item.coverArt ?? "",
        ),
      );
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
