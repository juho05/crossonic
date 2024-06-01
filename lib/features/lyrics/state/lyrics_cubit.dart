import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:crossonic/services/audio_handler/audio_handler.dart';
import 'package:equatable/equatable.dart';

part 'lyrics_state.dart';

class LyricsCubit extends Cubit<LyricsState> {
  final CrossonicAudioHandler _audioHandler;
  final APIRepository _apiRepository;

  late final StreamSubscription _currentMediaSubscription;

  LyricsCubit({
    required CrossonicAudioHandler audioHandler,
    required APIRepository apiRepository,
  })  : _audioHandler = audioHandler,
        _apiRepository = apiRepository,
        super(const LyricsState(status: FetchStatus.initial, lines: [])) {
    _currentMediaSubscription =
        _audioHandler.mediaQueue.current.listen((value) async {
      if (value == null) {
        emit(const LyricsState(
            status: FetchStatus.success, lines: [], noSong: true));
        return;
      }
      if (!value.currentChanged) return;
      await refresh(value.item.id);
    });
  }

  Future<void> refresh(String songID) async {
    emit(const LyricsState(
        status: FetchStatus.loading, lines: [], noSong: false));
    try {
      final lyrics = await _apiRepository.getLyricsBySongId(songID);
      final lines = !(lyrics.structuredLyrics?.isEmpty ?? true)
          ? lyrics.structuredLyrics![0].line.map((l) => l.value)
          : null;
      emit(state.copyWith(
          status: FetchStatus.success, lines: lines, noSong: false));
    } catch (e) {
      print(e);
      emit(state.copyWith(status: FetchStatus.failure));
    }
  }

  @override
  Future<void> close() async {
    await _currentMediaSubscription.cancel();
    return super.close();
  }
}
