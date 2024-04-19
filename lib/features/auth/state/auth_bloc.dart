import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:crossonic/repositories/auth/auth.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  late StreamSubscription<AuthStatus> _authStatusSubscription;

  AuthBloc({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(const AuthState.unknown()) {
    on<_AuthStatusChanged>(_onAuthStatusChanged);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    _authStatusSubscription = _authRepository.status
        .listen((status) => add(_AuthStatusChanged(status)));
  }

  Future<void> _onAuthStatusChanged(
    _AuthStatusChanged event,
    Emitter<AuthState> emit,
  ) async {
    switch (event.status) {
      case AuthStatus.unauthenticated:
        return emit(const AuthState.unauthenticated(false));
      case AuthStatus.unauthenticatedRestored:
        return emit(const AuthState.unauthenticated(true));
      case AuthStatus.authenticated:
        return emit(AuthState.authenticated(
            (await _authRepository.auth).username, false));
      case AuthStatus.authenticatedRestored:
        return emit(AuthState.authenticated(
            (await _authRepository.auth).username, true));
      case AuthStatus.unknown:
        return emit(const AuthState.unknown());
    }
  }

  void _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) {
    _authRepository.logout();
  }

  @override
  Future<void> close() {
    _authStatusSubscription.cancel();
    return super.close();
  }
}
