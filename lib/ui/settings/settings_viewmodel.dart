import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:flutter/material.dart';

class SettingsViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  bool _loggingOut = false;
  bool get loggingOut => _loggingOut;

  bool get supportsListenBrainz => _authRepository.serverFeatures.isCrossonic;

  SettingsViewModel({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository;

  Future<void> logout() async {
    _loggingOut = true;
    notifyListeners();
    await _authRepository.logout(true);
  }
}
