import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/subsonic/subsonic.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';

part 'albums_state.dart';
part 'albums_event.dart';

enum AlbumSortMode {
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
  final SubsonicRepository _subsonicRepository;

  AlbumsBloc(this._subsonicRepository) : super(const AlbumsState()) {
    on<AlbumsNextPageFetched>((event, emit) async {
      if (!state.reachedEnd) {
        await _fetch(albumsPerPage, state.albums.length, emit);
      }
    }, transformer: throttleDroppable(throttleDuration));
    on<AlbumSortModeSelected>((event, emit) async {
      if (_sortMode == event.mode) return;
      _sortMode = event.mode;
      await _fetch(albumsPerPage, 0, emit);
    });
  }

  AlbumSortMode _sortMode = AlbumSortMode.random;

  Future<void> _fetch(int count, int offset, Emitter<AlbumsState> emit) async {
    emit(state.copyWith(status: FetchStatus.loading, sortMode: _sortMode));
    try {
      final albums = (await _subsonicRepository.getAlbumList2(
        switch (_sortMode) {
          AlbumSortMode.alphabetical => GetAlbumList2Type.alphabeticalByName,
          AlbumSortMode.frequent => GetAlbumList2Type.frequent,
          AlbumSortMode.rating => GetAlbumList2Type.highest,
          AlbumSortMode.random => GetAlbumList2Type.random,
          AlbumSortMode.added => GetAlbumList2Type.newest,
          AlbumSortMode.lastPlayed => GetAlbumList2Type.recent,
          AlbumSortMode.releaseDate => GetAlbumList2Type.byYear,
        },
        size: min(count, 500),
        offset: offset,
        fromYear: _sortMode == AlbumSortMode.releaseDate ? 1 : null,
        toYear: _sortMode == AlbumSortMode.releaseDate ? 2300 : null,
      ))
          .map((album) => AlbumListItem(
                id: album.id,
                name: album.name,
                artist: album.artist ?? "Unknown artist",
                coverID: album.coverArt ?? "",
                year: album.year,
              ));
      emit(state.copyWith(
        status: FetchStatus.success,
        albums: [
          if (offset > 0) ...state.albums.sublist(0, offset),
          ...albums,
        ],
        reachedEnd: albums.isEmpty,
      ));
    } catch (e) {
      print(e);
      emit(state.copyWith(status: FetchStatus.failure));
    }
  }
}
