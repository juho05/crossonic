import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:crossonic/repositories/api/models/media_model.dart';
import 'package:crossonic/repositories/api/models/models.dart';
import 'package:crossonic/services/audio_handler/audio_handler.dart';
import 'package:crossonic/services/audio_handler/media_queue.dart';
import 'package:equatable/equatable.dart';

part 'now_playing_state.dart';

class NowPlayingCubit extends Cubit<NowPlayingState> {
  final CrossonicAudioHandler _audioHandler;
  late final StreamSubscription<CurrentMedia?> _currentMediaSubscription;
  late final StreamSubscription<bool> _loopSubscription;
  late final StreamSubscription<CrossonicPlaybackState>
      _playbackStateSubscription;
  NowPlayingCubit(CrossonicAudioHandler audioHandler)
      : _audioHandler = audioHandler,
        super(NowPlayingState(
            playbackState: const CrossonicPlaybackState(
                status: CrossonicPlaybackStatus.stopped),
            loop: audioHandler.mediaQueue.loop.value)) {
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
          media: value?.item,
          loop: _audioHandler.mediaQueue.loop.value,
        ),
      );
    });
    _playbackStateSubscription =
        _audioHandler.crossonicPlaybackStatus.listen((value) {
      final media = _audioHandler.mediaQueue.current.value?.item;
      emit(state.copyWith(
        playbackState: value,
        coverArtID: media?.coverArt,
        media: media,
        loop: _audioHandler.mediaQueue.loop.value,
      ));
    });
    _loopSubscription = _audioHandler.mediaQueue.loop.listen((loop) {
      emit(state.copyWith(
          coverArtID: state.coverArtID, media: state.media, loop: loop));
    });
  }

  void toggleLoop() {
    _audioHandler.mediaQueue.setLoop(!_audioHandler.mediaQueue.loop.value);
  }

  @override
  Future<void> close() async {
    await _currentMediaSubscription.cancel();
    await _playbackStateSubscription.cancel();
    await _loopSubscription.cancel();
    return super.close();
  }
}
