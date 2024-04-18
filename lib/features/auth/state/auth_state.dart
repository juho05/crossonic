part of 'auth_bloc.dart';

class AuthState extends Equatable {
  final AuthStatus status;
  final String username;

  const AuthState._({
    this.status = AuthStatus.unknown,
    this.username = "",
  });

  const AuthState.unknown() : this._();

  const AuthState.authenticated(String username)
      : this._(status: AuthStatus.authenticated, username: username);

  const AuthState.unauthenticated()
      : this._(status: AuthStatus.unauthenticated);

  @override
  List<Object?> get props => [status];
}
