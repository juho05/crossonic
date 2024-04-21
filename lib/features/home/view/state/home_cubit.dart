import 'package:bloc/bloc.dart';
import 'package:crossonic/repositories/subsonic/subsonic.dart';
import 'package:equatable/equatable.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._subsonicRepository) : super(const HomeState());
  final SubsonicRepository _subsonicRepository;

  Future<void> fetchRandomSongs() async {
    emit(state.copyWith(randomSongsStatus: RandomSongsStatus.loading));
    try {
      final songs = await _subsonicRepository.getRandomSongs(10);
      emit(state.copyWith(
        randomSongsStatus: RandomSongsStatus.success,
        randomSongs: songs,
      ));
    } catch (e) {
      print(e);
      emit(state.copyWith(randomSongsStatus: RandomSongsStatus.failure));
    }
  }
}
