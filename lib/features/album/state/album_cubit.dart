import 'package:bloc/bloc.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/api/api.dart';
import 'package:equatable/equatable.dart';

part 'album_state.dart';

class AlbumCubit extends Cubit<AlbumState> {
  AlbumCubit(this._apiRepository)
      : super(const AlbumState(
          status: FetchStatus.initial,
          id: "",
          name: "",
          year: 0,
          coverID: "",
          artists: Artists(artists: [], displayName: ""),
          songs: [],
          subsonicSongs: [],
          description: "",
        ));

  final APIRepository _apiRepository;
  String _albumID = "";

  void _loadInfo(String albumID) async {
    try {
      final info = await _apiRepository.getAlbumInfo2(albumID);
      emit(state.copyWith(
          description: info.notes ?? "", coverID: state.coverID));
    } catch (e) {
      emit(state.copyWith(description: "", coverID: state.coverID));
    }
  }

  void load(String albumID) async {
    if (albumID == _albumID) return;
    _loadInfo(albumID);
    _albumID = albumID;
    emit(state.copyWith(
      status: FetchStatus.loading,
      id: albumID,
      coverID: null,
    ));

    try {
      final album = await _apiRepository.getAlbum(albumID);
      final List<Track> songs;
      if (album.song != null) {
        songs = album.song!
            .map((s) => Track(
                  id: s.id,
                  title: s.title,
                  duration: s.duration != null
                      ? Duration(seconds: s.duration!)
                      : Duration.zero,
                  number: s.track ?? 0,
                ))
            .toList();
      } else {
        songs = [];
      }
      emit(
        state.copyWith(
          status: FetchStatus.success,
          name: album.name,
          year: album.year ?? 0,
          artists: APIRepository.getArtistsOfAlbum(album),
          songs: songs,
          subsonicSongs: album.song ?? [],
          coverID: album.coverArt,
        ),
      );
    } catch (e) {
      print(e);
      emit(state.copyWith(status: FetchStatus.failure, coverID: state.coverID));
    }
  }
}
