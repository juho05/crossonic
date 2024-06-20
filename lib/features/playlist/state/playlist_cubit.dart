import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/api/api.dart';
import 'package:crossonic/repositories/playlist/playlist_repository.dart';
import 'package:equatable/equatable.dart';

part 'playlist_state.dart';

class PlaylistCubit extends Cubit<PlaylistState> {
  PlaylistCubit(this._playlistRepository, String playlistID)
      : _playlistID = playlistID,
        super(const PlaylistState(
          status: FetchStatus.initial,
          reorderEnabled: false,
          id: "",
          name: "",
          songCount: 0,
          duration: Duration.zero,
          coverID: null,
          songs: [],
        )) {
    _playlistsSubscription = _playlistRepository.playlists.listen((playlists) {
      if (state.id.isEmpty) return;
      final playlist = playlists.firstWhere((p) => p.id == state.id);
      final newState = state.copyWith(
        status:
            playlist.entry == null ? FetchStatus.loading : FetchStatus.success,
        id: playlist.id,
        songCount: playlist.songCount,
        name: playlist.name,
        songs: playlist.entry ?? [],
        duration: Duration(seconds: playlist.duration),
        coverID: playlist.coverArt,
      );
      emit(newState);
    });
    _load();
  }

  final PlaylistRepository _playlistRepository;
  late final StreamSubscription _playlistsSubscription;
  final String _playlistID;

  void toggleReorder() {
    emit(state.copyWith(
        coverID: state.coverID, reorderEnabled: !state.reorderEnabled));
  }

  void reorder(int oldIndex, int newIndex) {
    final songs = List<Media>.from(state.songs);
    final song = songs.removeAt(oldIndex);
    songs.insert(oldIndex < newIndex ? newIndex - 1 : newIndex, song);
    emit(state.copyWith(coverID: state.coverID, songs: songs));
    _playlistRepository.moveTrackInPlaylist(state.id, oldIndex, newIndex);
  }

  void _load() {
    try {
      final playlist = _playlistRepository.getPlaylist(_playlistID);
      final newState = state.copyWith(
        status:
            playlist.entry == null ? FetchStatus.loading : FetchStatus.success,
        id: playlist.id,
        songCount: playlist.songCount,
        name: playlist.name,
        songs: playlist.entry ?? [],
        duration: Duration(seconds: playlist.duration),
        coverID: playlist.coverArt,
      );
      emit(newState);
    } catch (e) {
      print(e);
      emit(state.copyWith(status: FetchStatus.failure, coverID: state.coverID));
    }
  }

  @override
  Future<void> close() async {
    await _playlistsSubscription.cancel();
    return super.close();
  }
}
