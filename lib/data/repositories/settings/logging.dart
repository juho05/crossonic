import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

enum ReplayGainMode { disabled, track, album, auto }

class LoggingSettings extends ChangeNotifier {
  final KeyValueRepository _repo;

  static const String _levelKey = "logging.level";
  static const LogLevel _levelDefault =
      kDebugMode ? LogLevel.debug : LogLevel.info;
  LogLevel _level = _levelDefault;
  LogLevel get level => _level;

  LoggingSettings({required KeyValueRepository keyValueRepository})
      : _repo = keyValueRepository;

  Future<void> load() async {
    _level = LogLevel.values
        .byName(await _repo.loadString(_levelKey) ?? _levelDefault.name);
    Log.level = _level;

    notifyListeners();
  }

  void reset() {
    _level = _levelDefault;
    Log.level = _level;
    notifyListeners();
    _repo.remove(_levelKey);
  }

  set level(LogLevel level) {
    if (_level == level) return;
    _level = level;
    Log.level = level;
    notifyListeners();
    _repo.store(_levelKey, _level.name);
  }
}
