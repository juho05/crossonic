import 'package:crossonic/data/repositories/settings/replay_gain.dart';
import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:flutter/material.dart';

class ReplayGainViewModel extends ChangeNotifier {
  final SettingsRepository _settings;

  ReplayGainMode _mode;
  ReplayGainMode get mode => _mode;

  bool _preferServerFallback;
  bool get preferServerFallback => _preferServerFallback;

  double _fallbackGain;
  double get fallbackGain => _fallbackGain;

  ReplayGainViewModel({required SettingsRepository settings})
      : _settings = settings,
        _mode = settings.replayGain.mode,
        _preferServerFallback = settings.replayGain.preferServerFallbackGain,
        _fallbackGain = settings.replayGain.fallbackGain {
    _settings.replayGain.addListener(_onSettingsChanged);
  }

  void reset() {
    _settings.replayGain.reset();
  }

  void update({
    required ReplayGainMode mode,
    required bool preferServerFallback,
    required double fallbackGain,
  }) {
    _settings.replayGain.mode = mode;
    _settings.replayGain.preferServerFallbackGain = preferServerFallback;
    _settings.replayGain.fallbackGain = fallbackGain;
  }

  void _onSettingsChanged() {
    _mode = _settings.replayGain.mode;
    _preferServerFallback = _settings.replayGain.preferServerFallbackGain;
    _fallbackGain = _settings.replayGain.fallbackGain;
    notifyListeners();
  }

  @override
  void dispose() {
    _settings.replayGain.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
