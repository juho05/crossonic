import 'package:bloc/bloc.dart';
import 'package:crossonic/exceptions.dart';
import 'package:crossonic/features/login/models/models.dart';
import 'package:crossonic/repositories/api/api.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final APIRepository _apiRepository;
  LoginBloc({
    required APIRepository apiRepository,
  })  : _apiRepository = apiRepository,
        super(const LoginState()) {
    on<LoginInputChanged>(_onLoginInputChanged);
    on<LoginErrorReset>(_onErrorReset);
    on<LoginSubmitted>(_onSubmitted);
  }

  void _onLoginInputChanged(LoginInputChanged event, Emitter<LoginState> emit) {
    switch (event.name) {
      case "server_url":
        _onServerURLChanged(event.value, emit);
      case "username":
        _onUsernameChanged(event.value, emit);
      case "password":
        _onPasswordChanged(event.value, emit);
    }
  }

  void _onServerURLChanged(
    String newValue,
    Emitter<LoginState> emit,
  ) {
    final serverURL = ServerURL.dirty(newValue);
    emit(
      state.copyWith(
        status: FormzSubmissionStatus.initial,
        serverURL: serverURL,
        isValid: Formz.validate([serverURL, state.username, state.password]),
      ),
    );
  }

  void _onUsernameChanged(
    String newValue,
    Emitter<LoginState> emit,
  ) {
    final username = Username.dirty(newValue);
    emit(
      state.copyWith(
        status: FormzSubmissionStatus.initial,
        username: username,
        isValid: Formz.validate([state.serverURL, username, state.password]),
      ),
    );
  }

  void _onPasswordChanged(
    String newValue,
    Emitter<LoginState> emit,
  ) {
    final password = Password.dirty(newValue);
    emit(
      state.copyWith(
        status: FormzSubmissionStatus.initial,
        password: password,
        isValid: Formz.validate([state.serverURL, state.username, password]),
      ),
    );
  }

  void _onErrorReset(
    LoginErrorReset event,
    Emitter<LoginState> emit,
  ) {
    emit(state.copyWith(
        status: FormzSubmissionStatus.initial, error: LoginError.none));
  }

  Future<void> _onSubmitted(
      LoginSubmitted event, Emitter<LoginState> emit) async {
    if (state.isValid) {
      emit(state.copyWith(status: FormzSubmissionStatus.inProgress));
      try {
        await _apiRepository.login(
            state.serverURL.value, state.username.value, state.password.value);
        emit(state.copyWith(
            status: FormzSubmissionStatus.success, error: LoginError.none));
      } on ServerUnreachableException {
        emit(state.copyWith(
            status: FormzSubmissionStatus.failure,
            error: LoginError.connection));
      } on UnauthenticatedException {
        emit(state.copyWith(
            status: FormzSubmissionStatus.failure,
            error: LoginError.credentials));
      } on UnexpectedServerResponseException {
        emit(state.copyWith(
            status: FormzSubmissionStatus.failure,
            error: LoginError.connection));
      } on NotACrossonicServerException {
        emit(state.copyWith(
            status: FormzSubmissionStatus.failure,
            error: LoginError.notCrossonic));
      } catch (e) {
        print(e);
        emit(state.copyWith(
            status: FormzSubmissionStatus.failure,
            error: LoginError.unexpected));
      }
    }
  }
}
