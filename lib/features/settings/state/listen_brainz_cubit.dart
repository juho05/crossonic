import 'package:bloc/bloc.dart';
import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:crossonic/repositories/api/models/listenbrainz_model.dart';
import 'package:equatable/equatable.dart';

part 'listen_brainz_state.dart';

class ListenBrainzCubit extends Cubit<ListenBrainzState> {
  final APIRepository _apiRepository;
  ListenBrainzCubit({
    required apiRepository,
  })  : _apiRepository = apiRepository,
        super(
            const ListenBrainzState(status: ListenBrainzStatus.loadingConfig)) {
    _apiRepository.getListenBrainzConfig().then(
      (config) => {
        emit(ListenBrainzState(
            status: ListenBrainzStatus.configLoaded,
            listenBrainzUsername: config.listenBrainzUsername ?? ""))
      },
      onError: (e) {
        emit(const ListenBrainzState(
            status: ListenBrainzStatus.configLoadError));
        return ListenBrainzConfig(listenBrainzUsername: null);
      },
    );
  }

  void tokenChanged(String token) {
    emit(state.copyWith(
        status: ListenBrainzStatus.configLoaded, errorText: "", token: token));
  }

  Future<void> connect() async {
    if (state.token.isEmpty) {
      emit(state.copyWith(
          status: ListenBrainzStatus.submitError,
          errorText: "Please enter a valid API token"));
      return;
    }
    emit(state.copyWith(status: ListenBrainzStatus.submitting));
    try {
      final config = await _apiRepository.connectListenBrainz(state.token);
      emit(state.copyWith(
          status: ListenBrainzStatus.configLoaded,
          errorText: "",
          listenBrainzUsername: config.listenBrainzUsername ?? ""));
    } catch (_) {
      emit(state.copyWith(
          status: ListenBrainzStatus.submitError, errorText: "Invalid token"));
    }
  }

  Future<void> disconnect() async {
    emit(state.copyWith(
        status: ListenBrainzStatus.loadingConfig,
        errorText: "",
        listenBrainzUsername: ""));
    try {
      final config = await _apiRepository.connectListenBrainz("");
      emit(state.copyWith(
          status: ListenBrainzStatus.configLoaded,
          listenBrainzUsername: config.listenBrainzUsername ?? ""));
    } catch (_) {
      emit(state.copyWith(
        status: ListenBrainzStatus.configLoadError,
      ));
    }
  }
}
