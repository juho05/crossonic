import 'dart:async';
import 'dart:convert';

import 'package:crossonic/exceptions.dart';
import 'package:crossonic/repositories/auth/auth_models.dart';
import 'package:crossonic/repositories/auth/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthRepository {
  final _controller = StreamController<AuthStatus>();
  final http.Client _httpClient;
  final _storage = const FlutterSecureStorage();

  AuthRepository(this._httpClient);

  Future<bool> _restoreState() async {
    final baseURL = await _storage.read(key: "crossonic_auth_base_url");
    final subsonicURL = await _storage.read(key: "crossonic_auth_subsonic_url");
    final username = await _storage.read(key: "crossonic_auth_username");
    final password = await _storage.read(key: "crossonic_auth_password");
    final authToken = await _storage.read(key: "crossonic_auth_token");
    final authTokenExpiresStr =
        await _storage.read(key: "crossonic_auth_token_expires");
    if (baseURL == null ||
        subsonicURL == null ||
        username == null ||
        password == null ||
        authToken == null ||
        authTokenExpiresStr == null) {
      return false;
    }
    int authTokenExpires = int.parse(authTokenExpiresStr);
    _baseURL = baseURL;
    _subsonicURL = subsonicURL;
    _username = username;
    _password = password;
    _authToken = authToken;
    _authTokenExpires = authTokenExpires;
    return true;
  }

  Future<void> _storeState() async {
    await _storage.write(key: "crossonic_auth_base_url", value: _baseURL);
    await _storage.write(
        key: "crossonic_auth_subsonic_url", value: _subsonicURL);
    await _storage.write(key: "crossonic_auth_username", value: _username);
    await _storage.write(key: "crossonic_auth_password", value: _password);
    await _storage.write(key: "crossonic_auth_token", value: _authToken);
    await _storage.write(
        key: "crossonic_auth_token_expires",
        value: _authTokenExpires.toString());
  }

  Future<bool> _testAuthToken() async {
    try {
      final response = await http.get(Uri.parse('$_baseURL/ping'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Stream<AuthStatus> get status async* {
    yield AuthStatus.unknown;
    try {
      final authenticated = await _restoreState();
      if (!authenticated) {
        yield AuthStatus.unauthenticated;
      } else {
        try {
          await connect(_baseURL);
          if (_authTokenExpires <
                  (DateTime.now().millisecondsSinceEpoch / 1000.0) +
                      (3 * 60 * 60) ||
              !(await _testAuthToken())) {
            await login(_username, _password);
          }
          yield AuthStatus.authenticated;
        } on ServerUnreachableException {
          yield AuthStatus.authenticated;
        }
      }
    } catch (_) {
      yield AuthStatus.unauthenticated;
    }
    await _storeState();
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
    final response = await _httpClient.post(Uri.parse('$_baseURL/login'),
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
      final tokenExists = _authToken.isNotEmpty;
      final oldSubsonicURL = _subsonicURL;
      final auth = LoginResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
      _authToken = auth.authToken;
      _authTokenExpires = auth.expires;
      _subsonicURL = auth.subsonicURL;
      _username = username;
      _password = password;
      if (!tokenExists) {
        _controller.add(AuthStatus.authenticated);
        await _storeState();
      } else if (oldSubsonicURL != auth.subsonicURL) {
        logout();
        throw InvalidCredentialsException();
      }
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
    _storeState();
  }

  void dispose() => _controller.close();
}
