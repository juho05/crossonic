part of 'login_bloc.dart';

enum LoginError { none, connection, credentials, unexpected }

final class LoginState extends Equatable {
  final FormzSubmissionStatus status;
  final LoginError error;
  final ServerURL serverURL;
  final Username username;
  final Password password;
  final bool isValid;
  const LoginState({
    this.status = FormzSubmissionStatus.initial,
    this.error = LoginError.none,
    this.serverURL = const ServerURL.pure(),
    this.username = const Username.pure(),
    this.password = const Password.pure(),
    this.isValid = false,
  });

  LoginState copyWith({
    FormzSubmissionStatus? status,
    LoginError? error,
    ServerURL? serverURL,
    Username? username,
    Password? password,
    bool? isValid,
  }) {
    return LoginState(
      status: status ?? this.status,
      error: error ?? this.error,
      serverURL: serverURL ?? this.serverURL,
      username: username ?? this.username,
      password: password ?? this.password,
      isValid: isValid ?? this.isValid,
    );
  }

  @override
  List<Object> get props => [status, serverURL, username, password];
}
