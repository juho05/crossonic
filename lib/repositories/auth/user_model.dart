import 'package:equatable/equatable.dart';

class AuthModel extends Equatable {
  final String crossonicURL;
  final String subsonicURL;
  final String username;
  final String password;
  final String authToken;

  const AuthModel(
      {required this.crossonicURL,
      required this.subsonicURL,
      required this.username,
      required this.password,
      required this.authToken});

  static const AuthModel empty = AuthModel(
    crossonicURL: "",
    subsonicURL: "",
    authToken: "",
    username: "",
    password: "",
  );

  @override
  List<Object?> get props => [crossonicURL, username];
}
