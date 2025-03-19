import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

class DebugViewModel extends ChangeNotifier {
  final SettingsRepository _settings;

  LogLevel _level;
  LogLevel get level => _level;

  DebugViewModel({required SettingsRepository settings})
      : _settings = settings,
        _level = settings.logging.level {
    _settings.logging.addListener(_onSettingsChanged);
  }

  void reset() {
    _settings.logging.reset();
  }

  void update({
    required LogLevel level,
  }) {
    _settings.logging.level = level;
  }

  void _onSettingsChanged() {
    _level = _settings.logging.level;
    notifyListeners();
  }

  @override
  void dispose() {
    _settings.logging.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
