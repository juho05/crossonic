import 'package:bloc/bloc.dart';
import 'package:crossonic/exceptions.dart';
import 'package:crossonic/features/login/models/models.dart';
import 'package:crossonic/repositories/auth/auth.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository _authRepository;
  LoginBloc({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(const LoginState()) {
    on<LoginServerURLChanged>(_onServerURLChanged);
    on<LoginUsernameChanged>(_onUsernameChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginErrorReset>(_onErrorReset);
    on<LoginSubmitted>(_onSubmitted);
  }

  void _onServerURLChanged(
    LoginServerURLChanged event,
    Emitter<LoginState> emit,
  ) {
    final serverURL = ServerURL.dirty(event.serverURL);
    emit(
      state.copyWith(
        status: FormzSubmissionStatus.initial,
        serverURL: serverURL,
        isValid: Formz.validate([serverURL, state.username, state.password]),
      ),
    );
  }

  void _onUsernameChanged(
    LoginUsernameChanged event,
    Emitter<LoginState> emit,
  ) {
    final username = Username.dirty(event.username);
    emit(
      state.copyWith(
        status: FormzSubmissionStatus.initial,
        username: username,
        isValid: Formz.validate([state.serverURL, username, state.password]),
      ),
    );
  }

  void _onPasswordChanged(
    LoginPasswordChanged event,
    Emitter<LoginState> emit,
  ) {
    final password = Password.dirty(event.password);
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
        await _authRepository.connect(state.serverURL.value);
        await _authRepository.login(state.username.value, state.password.value);
        emit(state.copyWith(
            status: FormzSubmissionStatus.success, error: LoginError.none));
      } on ServerUnreachableException {
        emit(state.copyWith(
            status: FormzSubmissionStatus.failure,
            error: LoginError.connection));
      } on UnexpectedServerResponseException {
        emit(state.copyWith(
            status: FormzSubmissionStatus.failure,
            error: LoginError.connection));
      } on InvalidCredentialsException {
        emit(state.copyWith(
            status: FormzSubmissionStatus.failure,
            error: LoginError.credentials));
      } catch (e) {
        print(e);
        emit(state.copyWith(
            status: FormzSubmissionStatus.failure,
            error: LoginError.unexpected));
      }
    }
  }
}
