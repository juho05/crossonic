import 'package:crossonic/data/repositories/logger/log_repository.dart';
import 'package:flutter/material.dart';

class ChooseLogSessionPageViewModel extends ChangeNotifier {
  final LogRepository _repository;

  List<DateTime> _sessions;
  List<DateTime> get sessions => _sessions;

  ChooseLogSessionPageViewModel({required LogRepository logRepository})
      : _repository = logRepository,
        _sessions = const [] {
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    _sessions = await _repository.getSessions();
    notifyListeners();
  }
}
