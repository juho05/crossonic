import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/logger/log_message.dart';
import 'package:crossonic/data/repositories/logger/log_repository.dart';
import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:crossonic/utils/format.dart';
import 'package:crossonic/utils/result.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:share_plus/share_plus.dart';

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

  Future<void> changeSessionTime(DateTime sessionTime) async {
    if (_sessionTime == sessionTime) return;
    _searchDebounce?.cancel();
    _newMessageSubscription?.cancel();
    _newMessageSubscription = null;
    _logMessages = [];
    _filteredMessages = [];
    _sessionTime = sessionTime;
    await _loadMessages();
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
    if (enabledLevels.contains(msg.level)) {
      _updateFilteredLogMessages();
    }
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    _searchDebounce = null;
    _searchText = "";
    _updateFilteredLogMessages();
  }

  Future<Result<bool>> shareLog({
    required bool filtered,
  }) async {
    final timeStr = DateFormat("yyyy-MM-dd_HH-mm-ss").format(sessionTime);
    final bytes = utf8.encode(_exportLog(filtered: filtered));
    final fileName = "crossonic-logs_$timeStr.txt";

    final result = await SharePlus.instance.share(
      ShareParams(
        title: "Share logs",
        downloadFallbackEnabled: true,
        files: [
          XFile.fromData(bytes, mimeType: "text/plain", name: fileName),
        ],
        fileNameOverrides: [fileName],
      ),
    );
    if (result.status == ShareResultStatus.dismissed) {
      return const Result.ok(false);
    }
    return const Result.ok(true);
  }

  Future<Result<bool>> saveLog({
    required bool filtered,
  }) async {
    try {
      final timeStr = DateFormat("yyyy-MM-dd_HH-mm-ss").format(sessionTime);
      final bytes = utf8.encode(_exportLog(filtered: filtered));

      final outputFile = await FilePicker.platform.saveFile(
        fileName: "crossonic-logs_$timeStr.txt",
        bytes: bytes,
      );
      if (outputFile == null) {
        return const Result.ok(false);
      }
      // file_picker does not write the file on Linux for some reason
      if (!kIsWeb && Platform.isLinux) {
        await File(outputFile).writeAsBytes(bytes);
      }
    } on Exception catch (e) {
      return Result.error(e);
    }
    return const Result.ok(true);
  }

  String _exportLog({required bool filtered}) {
    String logStr =
        "========================= Crossonic Logs ${formatDateTime(sessionTime)} =========================\n";
    if (filtered) {
      logStr += _filteredMessages
          .map((msg) => msg.toString())
          .join("\n--------------------------------------------------\n");
    } else {
      logStr += _logMessages
          .map((msg) => msg.toString())
          .join("\n--------------------------------------------------\n");
    }
    return logStr;
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
