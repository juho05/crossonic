import 'package:bloc/bloc.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/subsonic/subsonic.dart';
import 'package:equatable/equatable.dart';

part 'recently_added_albums_state.dart';

class RecentlyAddedAlbumsCubit extends Cubit<RecentlyAddedAlbumsState> {
  RecentlyAddedAlbumsCubit(this._subsonicRepository)
      : super(const RecentlyAddedAlbumsState());
  final SubsonicRepository _subsonicRepository;

  Future<void> fetch(int count) async {
    emit(state.copyWith(status: FetchStatus.loading));
    try {
      final albums = await _fetch(count, 0);
      emit(state.copyWith(
        status: FetchStatus.success,
        albums: albums,
      ));
    } catch (e) {
      print(e);
      emit(state.copyWith(status: FetchStatus.failure));
    }
  }

  Future<List<RecentlyAddedAlbum>> _fetch(int count, int offset) async {
    return (await _subsonicRepository.getAlbumList2(GetAlbumList2Type.newest,
            size: count, offset: offset))
        .map((album) => RecentlyAddedAlbum(
              id: album.id,
              name: album.name,
              artist: album.artist ?? "Unknown artist",
              coverID: album.coverArt ?? "",
            ))
        .toList();
  }
}
