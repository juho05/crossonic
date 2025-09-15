import 'package:crossonic/data/repositories/auto_update/auto_update_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';

class InstallUpdateViewModel extends ChangeNotifier {
  final AutoUpdateRepository _repo;

  AutoUpdateStatus get status => _repo.status;
  ValueStream<double> get downloadProgress => _repo.downloadProgress;

  InstallUpdateViewModel({required AutoUpdateRepository autoUpdateRepository})
      : _repo = autoUpdateRepository {
    _repo.addListener(notifyListeners);
  }

  Future<Result<void>> installUpdate() async {
    final result = await _repo.update();
    if (result is Err) {
      Log.error("Auto update failed!", e: result.error);
    }
    return result;
  }

  @override
  void dispose() {
    _repo.removeListener(notifyListeners);
    super.dispose();
  }
}
