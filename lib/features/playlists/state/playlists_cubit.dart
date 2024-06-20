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

  PlaylistsCubit(PlaylistRepository playlistRepository)
      : _playlistRepository = playlistRepository,
        super(const PlaylistsState(playlists: [])) {
    _playlistsSubscription = _playlistRepository.playlists.listen((playlists) {
      emit(PlaylistsState(playlists: playlists));
    });
  }

  @override
  Future<void> close() async {
    await _playlistsSubscription.cancel();
    return super.close();
  }
}
