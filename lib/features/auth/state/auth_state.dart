part of 'auth_bloc.dart';

class AuthState extends Equatable {
  final AuthStatus status;
  final String username;
  final bool restored;

  const AuthState._({
    this.status = AuthStatus.unknown,
    this.username = "",
    this.restored = false,
  });

  const AuthState.unknown() : this._();

  const AuthState.authenticated(String username, bool restored)
      : this._(
            status: AuthStatus.authenticated,
            username: username,
            restored: restored);

  const AuthState.unauthenticated(bool restored)
      : this._(status: AuthStatus.unauthenticated, restored: restored);

  @override
  List<Object?> get props => [status, username, restored];
}
