import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/version/version_repository.dart';
import 'package:flutter/material.dart';

class SettingsViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final VersionRepository _versionRepository;

  bool _loggingOut = false;
  bool get loggingOut => _loggingOut;

  bool get supportsListenBrainz => _authRepository.serverFeatures.isCrossonic;

  Future<String> get version async =>
      "v${(await _versionRepository.getCurrentVersion())}";

  SettingsViewModel({
    required AuthRepository authRepository,
    required VersionRepository versionRepository,
  })  : _authRepository = authRepository,
        _versionRepository = versionRepository;

  Future<void> logout() async {
    _loggingOut = true;
    notifyListeners();
    await _authRepository.logout(true);
  }
}
