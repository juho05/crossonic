part of 'login_bloc.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

final class LoginInputChanged extends LoginEvent {
  const LoginInputChanged(this.name, this.value);
  final String name;
  final String value;
  @override
  List<Object> get props => [value];
}

final class LoginSubmitted extends LoginEvent {
  const LoginSubmitted();
}

final class LoginErrorReset extends LoginEvent {
  const LoginErrorReset();
}
