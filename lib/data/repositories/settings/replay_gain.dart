import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:flutter/material.dart';

enum ReplayGainMode { disabled, track, album, auto }

class ReplayGainSettings extends ChangeNotifier {
  final KeyValueRepository _repo;

  static const String _modeKey = "replay_gain.mode";
  static const ReplayGainMode _modeDefault = ReplayGainMode.disabled;
  ReplayGainMode _mode = _modeDefault;
  ReplayGainMode get mode => _mode;

  static const String _fallbackGainKey = "replay_gain.fallback_gain";
  static const double _fallbackGainDefault = -8;
  double _fallbackGain = _fallbackGainDefault;
  double get fallbackGain => _fallbackGain;

  static const String _preferServerFallbackGainKey =
      "replay_gain.prefer_server_fallback_gain";
  static const bool _preferServerFallbackGainDefault = true;
  bool _preferServerFallbackGain = _preferServerFallbackGainDefault;
  bool get preferServerFallbackGain => _preferServerFallbackGain;

  ReplayGainSettings({required KeyValueRepository keyValueRepository})
      : _repo = keyValueRepository;

  Future<void> load() async {
    _mode = ReplayGainMode.values
        .byName(await _repo.loadString(_modeKey) ?? _modeDefault.name);

    _fallbackGain =
        await _repo.loadDouble(_fallbackGainKey) ?? _fallbackGainDefault;

    _preferServerFallbackGain =
        await _repo.loadBool(_preferServerFallbackGainKey) ??
            _preferServerFallbackGainDefault;

    notifyListeners();
  }

  void reset() {
    _mode = _modeDefault;
    _fallbackGain = _fallbackGainDefault;
    _preferServerFallbackGain = _preferServerFallbackGainDefault;
    notifyListeners();
    _repo.remove(_modeKey);
    _repo.remove(_fallbackGainKey);
    _repo.remove(_preferServerFallbackGainKey);
  }

  set mode(ReplayGainMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    _repo.store(_modeKey, _mode.name);
  }

  set fallbackGain(double gain) {
    if (_fallbackGain == gain) return;
    _fallbackGain = gain;
    notifyListeners();
    _repo.store(_fallbackGainKey, _fallbackGain);
  }

  set preferServerFallbackGain(bool preferServer) {
    if (_preferServerFallbackGain == preferServer) return;
    _preferServerFallbackGain = preferServer;
    notifyListeners();
    _repo.store(_preferServerFallbackGainKey, _preferServerFallbackGain);
  }
}
