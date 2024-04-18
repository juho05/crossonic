import 'dart:async';
import 'dart:convert';

import 'package:crossonic/exceptions.dart';
import 'package:crossonic/repositories/auth/auth_models.dart';
import 'package:crossonic/repositories/auth/user_model.dart';
import 'package:http/http.dart' as http;

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthRepository {
  final _controller = StreamController<AuthStatus>();
  final http.Client httpClient;

  AuthRepository(this.httpClient);

  Stream<AuthStatus> get status async* {
    yield AuthStatus.unknown;
    // TODO: load auth state from disk
    await Future<void>.delayed(const Duration(milliseconds: 500));
    yield AuthStatus.unauthenticated;
    yield* _controller.stream;
  }

  String _baseURL = "";
  Future<void> connect(String baseURL) async {
    if (_baseURL == baseURL) return;
    logout();
    try {
      final response = await http.get(Uri.parse('$baseURL/ping?noAuth=true'));
      if (response.statusCode != 200) {
        throw ServerException(response.statusCode);
      }
      if (response.body != '"crossonic-success"') {
        throw UnexpectedServerResponseException();
      }
      _baseURL = baseURL;
    } catch (e) {
      throw ServerUnreachableException();
    }
  }

  String _subsonicURL = "";
  String _username = "";
  String _password = "";
  String _authToken = "";
  int _authTokenExpires = 0;

  Future<AuthModel> get auth async {
    if (_authToken.isEmpty || _username.isEmpty || _password.isEmpty) {
      throw UnauthenticatedException();
    }
    if (_authToken.isNotEmpty &&
        _authTokenExpires <
            (DateTime.now().millisecondsSinceEpoch / 1000.0) + (3 * 60 * 60)) {
      try {
        await login(_username, _password);
      } on InvalidCredentialsException {
        throw UnauthenticatedException();
      }
    }
    return AuthModel(
      crossonicURL: _baseURL,
      subsonicURL: _subsonicURL,
      username: _username,
      password: _password,
      authToken: _authToken,
    );
  }

  Future<void> login(String username, String password) async {
    if (_baseURL.isEmpty) {
      throw const InvalidStateException(
          "AuthRepository.connect must be successfully called before AuthRepository.login");
    }
    final response = await httpClient.post(Uri.parse('$_baseURL/login'),
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
        headers: {'Content-Type': 'application/json'});
    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        logout();
        throw InvalidCredentialsException();
      }
      throw ServerException(response.statusCode);
    }

    try {
      final auth = LoginResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
      if (_authToken.isEmpty) {
        _controller.add(AuthStatus.authenticated);
      } else if (_subsonicURL != auth.subsonicURL) {
        logout();
        throw InvalidCredentialsException();
      }
      _authToken = auth.authToken;
      _authTokenExpires = auth.expires;
      _subsonicURL = auth.subsonicURL;
      _username = username;
      _password = password;
    } catch (e) {
      throw UnexpectedServerResponseException();
    }
  }

  void logout() {
    if (_authToken.isNotEmpty) {
      _controller.add(AuthStatus.unauthenticated);
    }
    _username = "";
    _password = "";
    _authToken = "";
    _authTokenExpires = 0;
    _subsonicURL = "";
  }

  void dispose() => _controller.close();
}
