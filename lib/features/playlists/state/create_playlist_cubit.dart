import 'package:bloc/bloc.dart';
import 'package:crossonic/exceptions.dart';
import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:equatable/equatable.dart';

part 'create_playlist_state.dart';

class CreatePlaylistCubit extends Cubit<CreatePlaylistState> {
  final APIRepository _apiRepository;

  CreatePlaylistCubit(APIRepository apiRepository)
      : _apiRepository = apiRepository,
        super(const CreatePlaylistState(
            status: CreatePlaylistStatus.initial, name: ""));

  void nameChanged(String name) {
    emit(state.copyWith(status: CreatePlaylistStatus.none, name: name));
  }

  Future<void> submit() async {
    if (state.name.isEmpty) return;
    emit(state.copyWith(status: CreatePlaylistStatus.loading));
    try {
      await _apiRepository.createPlaylist(name: state.name);
      emit(state.copyWith(status: CreatePlaylistStatus.created));
    } on ServerUnreachableException {
      emit(state.copyWith(status: CreatePlaylistStatus.connectionError));
    } catch (e) {
      print(e);
      emit(state.copyWith(status: CreatePlaylistStatus.unexpectedError));
    }
  }
}
