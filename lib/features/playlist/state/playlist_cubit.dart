import 'dart:async';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/api/api.dart';
import 'package:crossonic/repositories/playlist/playlist_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';

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
          coverStatus: CoverStatus.none,
          downloadStatus: DownloadStatus.none,
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
        downloadStatus: !_playlistRepository.playlistDownloads.value
                .containsKey(playlist.id)
            ? DownloadStatus.none
            : (_playlistRepository.playlistDownloads.value[playlist.id]!
                ? DownloadStatus.downloaded
                : DownloadStatus.downloading),
      );
      emit(newState);
    });
    _downloadStatusSubscription =
        _playlistRepository.playlistDownloads.listen((downloads) {
      final status =
          !_playlistRepository.playlistDownloads.value.containsKey(state.id)
              ? DownloadStatus.none
              : (_playlistRepository.playlistDownloads.value[state.id]!
                  ? DownloadStatus.downloaded
                  : DownloadStatus.downloading);
      if (status != state.downloadStatus) {
        emit(state.copyWith(coverID: state.coverID, downloadStatus: status));
      }
    });
    _load();
  }

  final PlaylistRepository _playlistRepository;
  late final StreamSubscription _playlistsSubscription;
  late final StreamSubscription _downloadStatusSubscription;
  final String _playlistID;

  void toggleReorder() {
    emit(state.copyWith(
        coverID: state.coverID, reorderEnabled: !state.reorderEnabled));
  }

  Future<void> setCover() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    emit(state.copyWith(
        coverID: state.coverID, coverStatus: CoverStatus.uploading));
    final file = result.files[0];
    if (file.size > 15e6) {
      emit(state.copyWith(
          coverID: state.coverID, coverStatus: CoverStatus.fileTooBig));
      return;
    }
    try {
      await _playlistRepository.setPlaylistCover(
          state.id, file.extension ?? "", file.bytes!);
    } catch (e) {
      print(e);
      emit(state.copyWith(
          coverID: state.coverID, coverStatus: CoverStatus.uploadFailed));
    }
  }

  Future<void> removeCover() async {
    emit(state.copyWith(
        coverID: state.coverID, coverStatus: CoverStatus.uploading));
    try {
      await _playlistRepository.setPlaylistCover(state.id, "", Uint8List(0));
    } catch (e) {
      print(e);
      emit(state.copyWith(
          coverID: state.coverID, coverStatus: CoverStatus.uploadFailed));
    }
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
      final playlist = _playlistRepository.getPlaylistThenUpdate(_playlistID);
      final newState = state.copyWith(
        status:
            playlist.entry == null ? FetchStatus.loading : FetchStatus.success,
        id: playlist.id,
        songCount: playlist.songCount,
        name: playlist.name,
        songs: playlist.entry ?? [],
        duration: Duration(seconds: playlist.duration),
        coverID: playlist.coverArt,
        downloadStatus: !_playlistRepository.playlistDownloads.value
                .containsKey(playlist.id)
            ? DownloadStatus.none
            : (_playlistRepository.playlistDownloads.value[playlist.id]!
                ? DownloadStatus.downloaded
                : DownloadStatus.downloading),
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
    await _downloadStatusSubscription.cancel();
    return super.close();
  }
}
