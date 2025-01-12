import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/api/api.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';

part 'albums_state.dart';
part 'albums_event.dart';

enum AlbumSortMode {
  none,
  random,
  added,
  lastPlayed,
  rating,
  frequent,
  alphabetical,
  releaseDate,
}

const throttleDuration = Duration(milliseconds: 100);
const albumsPerPage = 30;

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class AlbumsBloc extends Bloc<AlbumsEvent, AlbumsState> {
  final APIRepository _apiRepository;

  AlbumsBloc(this._apiRepository) : super(const AlbumsState()) {
    on<AlbumsNextPageFetched>((event, emit) async {
      if (!state.reachedEnd) {
        await _fetch(albumsPerPage, state.albums.length, emit);
      }
    }, transformer: throttleDroppable(throttleDuration));
    on<AlbumSortModeSelected>((event, emit) async {
      if (_sortMode == event.mode) return;
      _sortMode = event.mode;
      await _fetch(
          _sortMode == AlbumSortMode.random ? 300 : albumsPerPage, 0, emit);
    });
    on<AlbumsRefresh>((event, emit) async {
      await _fetch(
          _sortMode == AlbumSortMode.random ? 300 : albumsPerPage, 0, emit);
    });
  }

  AlbumSortMode _sortMode = AlbumSortMode.none;

  Future<void> _fetch(int count, int offset, Emitter<AlbumsState> emit) async {
    emit(state.copyWith(
        status: FetchStatus.loading,
        sortMode: _sortMode,
        albums: offset == 0 ? [] : state.albums));
    try {
      final albums = (await _apiRepository.getAlbumList2(
        switch (_sortMode) {
          AlbumSortMode.alphabetical => GetAlbumList2Type.alphabeticalByName,
          AlbumSortMode.frequent => GetAlbumList2Type.frequent,
          AlbumSortMode.rating => GetAlbumList2Type.highest,
          AlbumSortMode.random => GetAlbumList2Type.random,
          AlbumSortMode.added => GetAlbumList2Type.newest,
          AlbumSortMode.lastPlayed => GetAlbumList2Type.recent,
          AlbumSortMode.releaseDate => GetAlbumList2Type.byYear,
          _ => GetAlbumList2Type.alphabeticalByName,
        },
        size: min(count, 300),
        offset: offset,
        fromYear: _sortMode == AlbumSortMode.releaseDate ? 1 : null,
        toYear: _sortMode == AlbumSortMode.releaseDate ? 2300 : null,
      ))
          .map((album) => AlbumListItem(
                id: album.id,
                name: album.name,
                artists: APIRepository.getArtistsOfAlbum(album),
                coverID: album.coverArt,
                year: album.year,
              ));
      emit(state.copyWith(
        status: FetchStatus.success,
        albums: [
          if (offset > 0) ...state.albums.sublist(0, offset),
          ...albums,
        ],
        reachedEnd: albums.isEmpty || _sortMode == AlbumSortMode.random,
      ));
    } catch (e) {
      print(e);
      emit(state.copyWith(status: FetchStatus.failure));
    }
  }
}
