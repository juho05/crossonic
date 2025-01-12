import 'package:bloc/bloc.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/api/api.dart';
import 'package:equatable/equatable.dart';

part 'songs_state.dart';

enum SongsSort { none, random }

class SongsCubit extends Cubit<SongsState> {
  final SongsSort _sort;

  static const int songsPerPage = 300;

  SongsCubit(this._apiRepository, this._sort) : super(const SongsState());
  final APIRepository _apiRepository;

  Future<void> load([int count = songsPerPage]) async {
    return _fetch(count, 0);
  }

  Future<void> nextPage() async {
    return _fetch(songsPerPage, state.songs.length);
  }

  bool _loading = false;

  Future<void> _fetch(int count, int offset) async {
    if (_loading) return;
    _loading = true;
    if (_sort == SongsSort.random) {
      return _fetchRandom(count);
    }
    emit(state.copyWith(status: FetchStatus.loading));
    try {
      final (_, _, songs) = await _apiRepository.search3("",
          songCount: count, songOffset: offset);
      final newSongs = List.of(state.songs)..addAll(songs);
      emit(state.copyWith(
        status: FetchStatus.success,
        songs: newSongs,
        reachedEnd: songs.isEmpty,
      ));
    } catch (e) {
      print(e);
      emit(state.copyWith(status: FetchStatus.failure));
    } finally {
      _loading = false;
    }
  }

  Future<void> _fetchRandom(int count) async {
    emit(state.copyWith(status: FetchStatus.loading));
    try {
      final songs = await _apiRepository.getRandomSongs(count);
      emit(state.copyWith(
        status: FetchStatus.success,
        songs: songs,
        reachedEnd: true,
      ));
    } catch (e) {
      print(e);
      emit(state.copyWith(status: FetchStatus.failure));
    } finally {
      _loading = false;
    }
  }
}
