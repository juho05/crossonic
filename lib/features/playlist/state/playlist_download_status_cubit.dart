import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:crossonic/repositories/playlist/playlist_repository.dart';
import 'package:equatable/equatable.dart';

part 'playlist_download_status_state.dart';

class PlaylistDownloadStatusCubit extends Cubit<PlaylistDownloadStatusState> {
  late final StreamSubscription _subscription;
  PlaylistDownloadStatusCubit(String playlistID, PlaylistRepository repository)
      : super(const PlaylistDownloadStatusState(
            waiting: true, downloadedSongsCount: 0)) {
    _subscription =
        repository.currentPlaylistDownloadedSongsCount.listen((status) {
      if (status == null || status.$1 != playlistID) {
        emit(const PlaylistDownloadStatusState(
            waiting: true, downloadedSongsCount: 0));
        return;
      }
      emit(PlaylistDownloadStatusState(
          waiting: false, downloadedSongsCount: status.$2));
    });
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
