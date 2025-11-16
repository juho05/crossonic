import 'package:crossonic/data/repositories/cover/cover_repository.dart';
import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class DebugViewModel extends ChangeNotifier {
  final SettingsRepository _settings;
  final CoverRepository _coverRepo;

  Level _level;
  Level get level => _level;

  bool _stopIsPause;
  bool get stopIsPause => _stopIsPause;

  DebugViewModel({
    required SettingsRepository settings,
    required CoverRepository coverRepo,
  }) : _settings = settings,
       _level = settings.logging.level,
       _stopIsPause = settings.workarounds.stopIsPause,
       _coverRepo = coverRepo {
    _settings.logging.addListener(_onSettingsChanged);
    _settings.workarounds.addListener(_onSettingsChanged);
  }

  void resetWorkarounds() {
    _settings.workarounds.reset();
  }

  set level(Level level) {
    _settings.logging.level = level;
  }

  set stopIsPause(bool stopIsPause) {
    _settings.workarounds.stopIsPause = stopIsPause;
  }

  void _onSettingsChanged() {
    _level = _settings.logging.level;
    _stopIsPause = _settings.workarounds.stopIsPause;
    notifyListeners();
  }

  @override
  void dispose() {
    _settings.logging.removeListener(_onSettingsChanged);
    _settings.workarounds.removeListener(_onSettingsChanged);
    super.dispose();
  }

  Future<void> clearCoverCache() async {
    await _coverRepo.emptyCache();
  }
}
