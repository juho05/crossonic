import 'package:bloc/bloc.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/api/api.dart';
import 'package:equatable/equatable.dart';

part 'recently_added_albums_state.dart';

class RecentlyAddedAlbumsCubit extends Cubit<RecentlyAddedAlbumsState> {
  RecentlyAddedAlbumsCubit(this._apiRepository)
      : super(const RecentlyAddedAlbumsState());
  final APIRepository _apiRepository;

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
    return (await _apiRepository.getAlbumList2(GetAlbumList2Type.newest,
            size: count, offset: offset))
        .map((album) => RecentlyAddedAlbum(
              id: album.id,
              name: album.name,
              artists: APIRepository.getArtistsOfAlbum(album),
              coverID: album.coverArt ?? "",
              year: album.year,
            ))
        .toList();
  }
}
