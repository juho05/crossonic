import 'dart:async';
import 'dart:io';

import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/linux_theme_detector/dbus_interface.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LinuxThemeDetector extends ChangeNotifier {
  static const _linuxThemePrefersDarkKey = "linux_theme_prefers_dark";

  late final DBusInterface _dbus;
  final KeyValueRepository _keyValue;

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get themeMode => _mode;

  StreamSubscription? _preferenceStreamSubscription;

  LinuxThemeDetector({
    required KeyValueRepository keyValue,
  }) : _keyValue = keyValue {
    if (!kIsWeb && Platform.isLinux) {
      _dbus = DBusInterface();
      _load();
    }
  }

  Future<void> _load() async {
    Log.debug("Loading preferred color scheme...");
    final cachedPrefersDark =
        await _keyValue.loadBool(_linuxThemePrefersDarkKey);
    if (cachedPrefersDark != null) {
      _mode = cachedPrefersDark ? ThemeMode.dark : ThemeMode.light;
      Log.debug("Cached color scheme is: ${_mode.name}");
      notifyListeners();
    }
    final previous = _mode;

    final dbusPreference = await _dbus.readThemePreference();
    if (dbusPreference != null) {
      switch (dbusPreference) {
        case 1:
          _mode = ThemeMode.dark;
        case 2:
          _mode = ThemeMode.light;
        default:
          _mode = ThemeMode.system;
      }
      Log.info(
          "Successfully loaded color scheme from dbus: $dbusPreference -> ${_mode.name}");
      if (_mode != previous) {
        notifyListeners();
      }
      await _updateCache();

      _preferenceStreamSubscription ??=
          _dbus.themePreferenceStream.listen((event) async {
        final prev = _mode;
        switch (event) {
          case 1:
            _mode = ThemeMode.dark;
          case 2:
            _mode = ThemeMode.light;
          default:
            _mode = ThemeMode.system;
        }
        Log.info(
            "Detected color scheme change via dbus. New value: $event -> ${_mode.name}");
        if (_mode != prev) {
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
            _mode = ThemeMode.light;
          } else if (result.contains("dark")) {
            _mode = ThemeMode.dark;
          } else {
            _mode = ThemeMode.system;
          }
          Log.info(
              "Successfully loaded color scheme from gsettings color-scheme key: $result -> ${_mode.name}");
          if (_mode != previous) {
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
          _mode = ThemeMode.dark;
          Log.info(
              "Successfully loaded color scheme from gsettings gtk-theme key: $result -> ${_mode.name}");
          if (_mode != previous) {
            notifyListeners();
          }
          await _updateCache();
          return;
        }
      }
    } catch (_) {}

    if (_mode != ThemeMode.system) {
      _mode = ThemeMode.system;
      Log.warn("No color scheme detected: falling back to ThemeMode.system");
      if (_mode != previous) {
        notifyListeners();
      }
      await _keyValue.remove(_linuxThemePrefersDarkKey);
    }
  }

  Future<void> _updateCache() async {
    switch (_mode) {
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
    super.dispose();
  }
}
