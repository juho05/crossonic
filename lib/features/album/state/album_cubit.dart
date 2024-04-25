import 'package:bloc/bloc.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/subsonic/subsonic.dart';
import 'package:equatable/equatable.dart';

part 'album_state.dart';

class AlbumCubit extends Cubit<AlbumState> {
  AlbumCubit(this._subsonicRepository)
      : super(const AlbumState(
          status: FetchStatus.initial,
          id: "",
          name: "",
          year: 0,
          coverID: "",
          artistID: "",
          artistName: "",
          songs: [],
          subsonicSongs: [],
        ));

  final SubsonicRepository _subsonicRepository;
  String _albumID = "";

  void updateID(String albumID) async {
    if (albumID == _albumID) return;
    _albumID = albumID;
    emit(state.copyWith(
      status: FetchStatus.loading,
      id: albumID,
    ));

    try {
      final album = await _subsonicRepository.getAlbum(albumID);
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
                  isFavorite: s.starred != null,
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
          artistID: album.artistID ?? "",
          artistName: album.artist ?? "Unknown artist",
          songs: songs,
          subsonicSongs: album.song ?? [],
          coverID: album.coverArt ?? "",
        ),
      );
    } catch (e) {
      print(e);
      emit(state.copyWith(status: FetchStatus.failure));
    }
  }
}
