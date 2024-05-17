import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:crossonic/repositories/api/api.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final APIRepository _apiRepository;
  late StreamSubscription<AuthStatus> _authStatusSubscription;

  AuthBloc({
    required APIRepository apiRepository,
  })  : _apiRepository = apiRepository,
        super(const AuthState.unknown()) {
    on<_AuthStatusChanged>(_onAuthStatusChanged);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    _authStatusSubscription = _apiRepository.authStatus
        .listen((status) => add(_AuthStatusChanged(status)));
  }

  Future<void> _onAuthStatusChanged(
    _AuthStatusChanged event,
    Emitter<AuthState> emit,
  ) async {
    switch (event.status) {
      case AuthStatus.unauthenticated:
        return emit(const AuthState.unauthenticated());
      case AuthStatus.authenticated:
        return emit(AuthState.authenticated(_apiRepository.username));
      case AuthStatus.unknown:
        return emit(const AuthState.unknown());
    }
  }

  void _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) {
    _apiRepository.logout();
  }

  @override
  Future<void> close() {
    _authStatusSubscription.cancel();
    return super.close();
  }
}
