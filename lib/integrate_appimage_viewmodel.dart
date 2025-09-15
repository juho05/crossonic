import 'package:crossonic/data/repositories/appimage/appimage_repository.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/foundation.dart';

class IntegrateAppImageViewModel extends ChangeNotifier {
  final AppImageRepository _repo;

  bool _askToIntegrate = false;
  bool get askToIntegrate => _askToIntegrate;

  IntegrateAppImageViewModel({
    required AppImageRepository appImageRepository,
  }) : _repo = appImageRepository;

  Future<void> check() async {
    final shouldIntegrate = await _repo.shouldIntegrate();
    if (!shouldIntegrate) {
      return;
    }
    _askToIntegrate = true;
    notifyListeners();
  }

  void shownDialog() async {
    _askToIntegrate = false;
  }

  Future<void> disable() async {
    _askToIntegrate = false;
    await _repo.disableIntegration();
  }

  Future<Result<void>> integrate() async {
    _askToIntegrate = false;
    return await _repo.integrate();
  }
}
