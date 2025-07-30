import 'package:crossonic/data/repositories/settings/appearance.dart';
import 'package:flutter/material.dart';

class AppearanceViewModel extends ChangeNotifier {
  final AppearanceSettings _settings;

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  bool _dynamicColors = true;
  bool get dynamicColors => _dynamicColors;

  AppearanceViewModel({
    required AppearanceSettings settings,
  }) : _settings = settings {
    _settings.addListener(_onSettingsChanged);
    _onSettingsChanged();
  }

  void _onSettingsChanged() {
    _mode = _settings.themeMode;
    _dynamicColors = _settings.dynamicColors;
    notifyListeners();
  }

  void updateMode(ThemeMode mode) {
    _settings.themeMode = mode;
  }

  void updateDynamicColors(bool enable) {
    _settings.dynamicColors = enable;
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
