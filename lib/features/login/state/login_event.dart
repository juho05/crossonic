part of 'login_bloc.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

final class LoginServerURLChanged extends LoginEvent {
  const LoginServerURLChanged(this.serverURL);
  final String serverURL;
  @override
  List<Object> get props => [serverURL];
}

final class LoginUsernameChanged extends LoginEvent {
  const LoginUsernameChanged(this.username);
  final String username;
  @override
  List<Object> get props => [username];
}

final class LoginPasswordChanged extends LoginEvent {
  const LoginPasswordChanged(this.password);
  final String password;
  @override
  List<Object> get props => [password];
}

final class LoginSubmitted extends LoginEvent {
  const LoginSubmitted();
}

final class LoginErrorReset extends LoginEvent {
  const LoginErrorReset();
}
