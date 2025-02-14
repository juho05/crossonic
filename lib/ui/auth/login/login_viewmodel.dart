import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/utils/command.dart';
import 'package:crossonic/utils/exceptions.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

enum AuthType { apiKey, token, password }

class InvalidCredentialsException extends AppException {
  InvalidCredentialsException(super.message);
}

class LoginData {
  final AuthType type;
  final String? username;
  final String? password;
  final String? apiKey;

  LoginData({
    required this.type,
    required this.username,
    required this.password,
    required this.apiKey,
  });
}

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  List<AuthType> get supportedAuthTypes {
    return [
      if (_authRepository.serverFeatures.apiKeyAuthentication.contains(1))
        AuthType.apiKey,
      if (_authRepository.serverFeatures.supportsTokenAuth) AuthType.token,
      if (_authRepository.serverFeatures.supportsPasswordAuth)
        AuthType.password,
    ];
  }

  String get serverURL => _authRepository.serverUri?.host ?? "none";

  late final Command1<void, LoginData> login;

  LoginViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository {
    login = Command1(_login);
  }

  Future<void> resetServerUri() async {
    await _authRepository.logout(false);
  }

  Future<Result<void>> _login(LoginData data) async {
    if (data.type == AuthType.apiKey) {
      return await _authRepository.loginApiKey(data.apiKey!);
    }
    return await _authRepository.loginUsernamePassword(
        data.username!, data.password!, data.type == AuthType.token);
  }
}
