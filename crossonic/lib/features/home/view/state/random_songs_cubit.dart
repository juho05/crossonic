import 'package:bloc/bloc.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/subsonic/subsonic.dart';
import 'package:equatable/equatable.dart';

part 'random_songs_state.dart';

class RandomSongsCubit extends Cubit<RandomSongsState> {
  RandomSongsCubit(this._subsonicRepository) : super(const RandomSongsState());
  final SubsonicRepository _subsonicRepository;

  Future<void> fetch(int count) async {
    emit(state.copyWith(status: FetchStatus.loading));
    try {
      final songs = await _subsonicRepository.getRandomSongs(count);
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
