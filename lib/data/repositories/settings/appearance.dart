import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:flutter/material.dart';

class AppearanceSettings extends ChangeNotifier {
  final KeyValueRepository _repo;

  static const String _themeModeKey = "appearance.theme_mode";
  static const ThemeMode _themeModeDefault = ThemeMode.system;
  ThemeMode _themeMode = _themeModeDefault;
  ThemeMode get themeMode => _themeMode;

  static const String _dynamicColorsKey = "appearance.dynamic_colors";
  static const bool _dynamicColorsDefault = true;
  bool _dynamicColors = _dynamicColorsDefault;
  bool get dynamicColors => _dynamicColors;

  AppearanceSettings({required KeyValueRepository keyValueRepository})
      : _repo = keyValueRepository;

  Future<void> load() async {
    _themeMode = ThemeMode.values.byName(
        (await _repo.loadString(_themeModeKey)) ?? _themeModeDefault.name);
    _dynamicColors =
        await _repo.loadBool(_dynamicColorsKey) ?? _dynamicColorsDefault;
    notifyListeners();
  }

  void reset() {
    _themeMode = _themeModeDefault;
    _dynamicColors = _dynamicColorsDefault;
    notifyListeners();
    _repo.remove(_themeModeKey);
    _repo.remove(_dynamicColorsKey);
  }

  set themeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    _repo.store(_themeModeKey, _themeMode.name);
  }

  set dynamicColors(bool enable) {
    if (enable == _dynamicColors) return;
    _dynamicColors = enable;
    notifyListeners();
    _repo.store(_dynamicColorsKey, _dynamicColors);
  }
}
