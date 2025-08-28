import 'dart:async';

import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/logger/log_message.dart';
import 'package:crossonic/data/repositories/logger/log_repository.dart';
import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class LogsPageViewModel extends ChangeNotifier {
  final SettingsRepository _settings;
  final LogRepository _repository;

  StreamSubscription? _newMessageSubscription;

  DateTime _sessionTime;
  DateTime get sessionTime => _sessionTime;

  List<LogMessage> _logMessages;
  List<LogMessage> _filteredMessages;
  List<LogMessage> get logMessages => _filteredMessages;

  Set<Level> _enabledLevels;
  Set<Level> get enabledLevels => _enabledLevels;

  String _searchText;
  String get searchText => _searchText;

  LogsPageViewModel({
    required SettingsRepository settingsRepository,
    required LogRepository logRepository,
  })  : _settings = settingsRepository,
        _repository = logRepository,
        _sessionTime = Log.sessionStartTime,
        _logMessages = const [],
        _filteredMessages = const [],
        _enabledLevels = const {},
        _searchText = "" {
    _enabledLevels = [
      Level.trace,
      Level.debug,
      Level.info,
      Level.warning,
      Level.error,
      Level.fatal,
    ].where((l) => l >= _settings.logging.level).toSet();
    _loadMessages();
  }

  Future<void> enableMessageStream(bool loadNewMessages) async {
    if (sessionTime != Log.sessionStartTime) return;
    bool oldValue = _newMessageSubscription != null;
    if (oldValue == loadNewMessages) return;
    if (loadNewMessages) {
      await _loadMessages();
    } else {
      _newMessageSubscription?.cancel();
      _newMessageSubscription = null;
    }
  }

  set enabledLevels(Set<Level> levels) {
    _enabledLevels = levels;
    _updateFilteredLogMessages();
  }

  Timer? _searchDebounce;
  void search(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      _searchText = query;
      _updateFilteredLogMessages();
    });
  }

  Future<void> _loadMessages() async {
    _newMessageSubscription?.cancel();
    _newMessageSubscription = null;

    _logMessages = (await _repository.getMessages(sessionTime));

    if (sessionTime == Log.sessionStartTime) {
      _newMessageSubscription =
          _repository.newMessageStream.listen(_onNewMessage);
    }

    _updateFilteredLogMessages();
  }

  void _onNewMessage(LogMessage msg) async {
    if (_logMessages.isEmpty) {
      _logMessages = [msg];
    } else {
      _logMessages.add(msg);
    }
    _updateFilteredLogMessages();
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    _searchDebounce = null;
    _searchText = "";
    _updateFilteredLogMessages();
  }

  void _updateFilteredLogMessages() {
    _filteredMessages = _logMessages
        .where((m) =>
            enabledLevels.contains(m.level) &&
            (searchText.isEmpty ||
                m.tag.contains(searchText) ||
                m.message.contains(searchText)))
        .toList();
    notifyListeners();
  }

  @override
  void dispose() {
    _newMessageSubscription?.cancel();
    _newMessageSubscription = null;
    super.dispose();
  }
}
