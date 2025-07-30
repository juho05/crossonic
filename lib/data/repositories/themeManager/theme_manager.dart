import 'dart:async';
import 'dart:io';

import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/settings/appearance.dart';
import 'package:crossonic/data/repositories/themeManager/dbus_interface.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ThemeManager extends ChangeNotifier {
  static const _linuxThemePrefersDarkKey = "linux_theme_prefers_dark";

  late final DBusInterface _dbus;
  final KeyValueRepository _keyValue;
  final AppearanceSettings _settings;

  ThemeMode _systemMode = ThemeMode.system;

  ThemeMode _settingsThemeMode = ThemeMode.system;
  ThemeMode get themeMode =>
      _settingsThemeMode == ThemeMode.system ? _systemMode : _settingsThemeMode;

  bool _enableDynamicColors = true;
  bool get enableDynamicColors => _enableDynamicColors;

  StreamSubscription? _preferenceStreamSubscription;

  ThemeManager({
    required KeyValueRepository keyValue,
    required AppearanceSettings appearanceSettings,
  })  : _keyValue = keyValue,
        _settings = appearanceSettings {
    if (!kIsWeb && Platform.isLinux) {
      _dbus = DBusInterface();
      _loadLinuxSystemTheme();
    }
    appearanceSettings.addListener(_settingsChanged);
    _settingsChanged();
  }

  void _settingsChanged() {
    if (_settings.themeMode == _settingsThemeMode &&
        _settings.dynamicColors == _enableDynamicColors) {
      return;
    }
    _settingsThemeMode = _settings.themeMode;
    _enableDynamicColors = _settings.dynamicColors;
    notifyListeners();
  }

  Future<void> _loadLinuxSystemTheme() async {
    Log.debug("Loading preferred color scheme...");
    final cachedPrefersDark =
        await _keyValue.loadBool(_linuxThemePrefersDarkKey);
    if (cachedPrefersDark != null) {
      _systemMode = cachedPrefersDark ? ThemeMode.dark : ThemeMode.light;
      Log.debug("Cached color scheme is: ${_systemMode.name}");
      notifyListeners();
    }
    final previous = _systemMode;

    final dbusPreference = await _dbus.readThemePreference();
    if (dbusPreference != null) {
      switch (dbusPreference) {
        case 1:
          _systemMode = ThemeMode.dark;
        case 2:
          _systemMode = ThemeMode.light;
        default:
          _systemMode = ThemeMode.system;
      }
      Log.info(
          "Successfully loaded color scheme from dbus: $dbusPreference -> ${_systemMode.name}");
      if (_systemMode != previous) {
        notifyListeners();
      }
      await _updateCache();

      _preferenceStreamSubscription ??=
          _dbus.themePreferenceStream.listen((event) async {
        final prev = _systemMode;
        switch (event) {
          case 1:
            _systemMode = ThemeMode.dark;
          case 2:
            _systemMode = ThemeMode.light;
          default:
            _systemMode = ThemeMode.system;
        }
        Log.info(
            "Detected color scheme change via dbus. New value: $event -> ${_systemMode.name}");
        if (_systemMode != prev) {
          notifyListeners();
        }
        await _updateCache();
      });
      return;
    }

    try {
      final gsettingsResult = await Process.run(
          "gsettings", ["get", "org.gnome.desktop.interface", "color-scheme"]);
      if (gsettingsResult.exitCode == 0) {
        final result = (gsettingsResult.stdout as String).toLowerCase();
        if (result.isNotEmpty) {
          if (result.contains("light")) {
            _systemMode = ThemeMode.light;
          } else if (result.contains("dark")) {
            _systemMode = ThemeMode.dark;
          } else {
            _systemMode = ThemeMode.system;
          }
          Log.info(
              "Successfully loaded color scheme from gsettings color-scheme key: $result -> ${_systemMode.name}");
          if (_systemMode != previous) {
            notifyListeners();
          }
          await _updateCache();
          return;
        }
      }
    } catch (_) {}

    try {
      final gsettingsResult = await Process.run(
          "gsettings", ["get", "org.gnome.desktop.interface", "gtk-theme"]);
      if (gsettingsResult.exitCode == 0) {
        final result = gsettingsResult.stdout as String;
        if (result.isNotEmpty && result.contains("dark")) {
          _systemMode = ThemeMode.dark;
          Log.info(
              "Successfully loaded color scheme from gsettings gtk-theme key: $result -> ${_systemMode.name}");
          if (_systemMode != previous) {
            notifyListeners();
          }
          await _updateCache();
          return;
        }
      }
    } catch (_) {}

    if (_systemMode != ThemeMode.system) {
      _systemMode = ThemeMode.system;
      Log.warn("No color scheme detected: falling back to ThemeMode.system");
      if (_systemMode != previous) {
        notifyListeners();
      }
      await _keyValue.remove(_linuxThemePrefersDarkKey);
    }
  }

  Future<void> _updateCache() async {
    switch (_systemMode) {
      case ThemeMode.light:
        await _keyValue.store(_linuxThemePrefersDarkKey, false);
      case ThemeMode.dark:
        await _keyValue.store(_linuxThemePrefersDarkKey, true);
      case ThemeMode.system:
        await _keyValue.remove(_linuxThemePrefersDarkKey);
    }
  }

  @override
  void dispose() {
    _preferenceStreamSubscription?.cancel();
    _settings.removeListener(_settingsChanged);
    super.dispose();
  }
}
