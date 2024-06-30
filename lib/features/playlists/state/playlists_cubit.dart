import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/api/models/playlist_model.dart';
import 'package:crossonic/repositories/playlist/playlist_repository.dart';
import 'package:equatable/equatable.dart';

part 'playlists_state.dart';

class PlaylistsCubit extends Cubit<PlaylistsState> {
  final PlaylistRepository _playlistRepository;

  late final StreamSubscription _playlistsSubscription;
  late final StreamSubscription _downloadsSubscription;

  PlaylistsCubit(PlaylistRepository playlistRepository)
      : _playlistRepository = playlistRepository,
        super(const PlaylistsState(playlists: [], playlistDownloads: {})) {
    _playlistsSubscription = _playlistRepository.playlists.listen((playlists) {
      emit(state.copyWith(playlists: playlists));
    });
    _downloadsSubscription =
        _playlistRepository.playlistDownloads.listen((downloads) {
      emit(state.copyWith(playlistDownloads: downloads));
    });
  }

  @override
  Future<void> close() async {
    await _playlistsSubscription.cancel();
    await _downloadsSubscription.cancel();
    return super.close();
  }
}
