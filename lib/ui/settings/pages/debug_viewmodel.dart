import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class DebugViewModel extends ChangeNotifier {
  final SettingsRepository _settings;

  Level _level;
  Level get level => _level;

  DebugViewModel({required SettingsRepository settings})
      : _settings = settings,
        _level = settings.logging.level {
    _settings.logging.addListener(_onSettingsChanged);
  }

  void reset() {
    _settings.logging.reset();
  }

  void update({
    required Level level,
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
