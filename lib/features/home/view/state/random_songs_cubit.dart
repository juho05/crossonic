import 'package:bloc/bloc.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/api/api.dart';
import 'package:equatable/equatable.dart';

part 'random_songs_state.dart';

class RandomSongsCubit extends Cubit<RandomSongsState> {
  RandomSongsCubit(this._apiRepository) : super(const RandomSongsState());
  final APIRepository _apiRepository;

  Future<void> fetch(int count) async {
    emit(state.copyWith(status: FetchStatus.loading));
    try {
      final songs = await _apiRepository.getRandomSongs(count);
      emit(state.copyWith(
        status: FetchStatus.success,
        songs: songs,
      ));
    } catch (e) {
      print(e);
      emit(state.copyWith(status: FetchStatus.failure));
    }
  }
}
