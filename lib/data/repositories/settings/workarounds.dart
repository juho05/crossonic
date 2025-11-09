import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:flutter/material.dart';

class WorkaroundSettings extends ChangeNotifier {
  final KeyValueRepository _repo;

  static const String _stopIsPauseKey = "workarounds.stop_is_pause";
  bool _stopIsPause = false;
  bool get stopIsPause => _stopIsPause;

  WorkaroundSettings({required KeyValueRepository keyValueRepository})
    : _repo = keyValueRepository;

  Future<void> load() async {
    Log.trace("loading workaround settings");
    _stopIsPause = await _repo.loadBool(_stopIsPauseKey) ?? false;
    notifyListeners();
  }

  void reset() {
    Log.debug("resetting workaround settings");
    _stopIsPause = false;
    notifyListeners();
    _repo.remove(_stopIsPauseKey);
  }

  set stopIsPause(bool stopIsPause) {
    if (stopIsPause == _stopIsPause) return;
    Log.debug("stop is pause: $stopIsPause");
    _stopIsPause = stopIsPause;
    notifyListeners();
    if (stopIsPause) {
      _repo.store(_stopIsPauseKey, true);
    } else {
      _repo.remove(_stopIsPauseKey);
    }
  }
}
