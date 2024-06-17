import 'package:bloc/bloc.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/api/api.dart';
import 'package:equatable/equatable.dart';

part 'artist_state.dart';

class ArtistCubit extends Cubit<ArtistState> {
  ArtistCubit(this._apiRepository)
      : super(const ArtistState(
          status: FetchStatus.initial,
          id: "",
          name: "",
          albumCount: 0,
          coverID: "",
          albums: [],
          genres: [],
        ));

  final APIRepository _apiRepository;
  String _artistID = "";

  void load(String artistID) async {
    if (artistID == _artistID) return;
    _artistID = artistID;
    emit(state.copyWith(
      status: FetchStatus.loading,
      id: artistID,
    ));

    try {
      final artist = await _apiRepository.getArtist(artistID);
      final List<ArtistAlbum> albums;
      List<String> genres = [];
      if (artist.album != null) {
        albums = artist.album!.map((a) {
          genres.addAll((a.genres ?? []).map((g) => g.name));
          return ArtistAlbum(
            id: a.id,
            name: a.name,
            coverID: a.coverArt ?? "",
            year: a.year,
            artists: APIRepository.getArtistsOfAlbum(a).artists.toList(),
          );
        }).toList()
          ..sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
      } else {
        albums = [];
      }
      final distinctGenres = genres.toSet().toList();
      final Map<String, int> occurrenceCount = {};
      for (var genre in genres) {
        occurrenceCount[genre] = (occurrenceCount[genre] ?? 0) + 1;
      }
      distinctGenres
          .removeWhere((genre) => genre.toLowerCase().contains("unknown"));
      distinctGenres
          .sort((a, b) => occurrenceCount[b]!.compareTo(occurrenceCount[a]!));
      emit(
        state.copyWith(
          status: FetchStatus.success,
          id: artist.id,
          name: artist.name,
          albumCount: artist.albumCount ?? 0,
          albums: albums,
          coverID: artist.coverArt ?? "",
          genres: distinctGenres,
        ),
      );
    } catch (e) {
      print(e);
      emit(state.copyWith(status: FetchStatus.failure));
    }
  }
}
