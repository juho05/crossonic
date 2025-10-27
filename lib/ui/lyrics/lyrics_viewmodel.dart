import 'dart:async';

import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/subsonic/models/lyrics.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class LyricsViewModel extends ChangeNotifier {
  final SubsonicRepository _subsonic;
  final AudioHandler _audioHandler;
  StreamSubscription? _currentSubscription;
  StreamSubscription? _statusSubscription;

  bool get supportsSync => _lyrics?.synced ?? false;

  bool _syncedMode = true;
  bool get syncedMode => _syncedMode && supportsSync;

  set syncedMode(bool sync) {
    if (syncedMode == sync) return;
    _syncedMode = sync;
    _onPositionChanged(force: true);
    _updatePositionTimer();
    _updateWakelock();
    notifyListeners();
  }

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  Song? _currentSong;
  Song? get currentSong => _currentSong;

  Lyrics? _lyrics;
  Lyrics? get lyrics => _lyrics;

  final BehaviorSubject<int?> _selectedLine = BehaviorSubject.seeded(null);
  ValueStream<int?> get selectedLine => _selectedLine.stream;

  LyricsViewModel({
    required SubsonicRepository subsonic,
    required AudioHandler audioHandler,
  }) : _subsonic = subsonic,
       _audioHandler = audioHandler {
    _currentSubscription = _audioHandler.queue.current.listen((current) {
      _currentSong = current;
      _fetch();
    });
    _statusSubscription = _audioHandler.playbackStatus.listen(_onStatusChanged);
  }

  Future<void> _fetch() async {
    _lyrics = null;
    _onPositionChanged();
    if (_currentSong == null) {
      _status = FetchStatus.success;
      notifyListeners();
      return;
    }
    _status = FetchStatus.loading;
    notifyListeners();
    final result = await _subsonic.getLyricsLines(_currentSong!);
    switch (result) {
      case Err():
        _status = FetchStatus.failure;
        notifyListeners();
        return;
      case Ok():
    }
    _status = FetchStatus.success;
    _lyrics = result.value;
    _syncedMode = supportsSync;
    _updatePositionTimer();
    _updateWakelock();
    notifyListeners();
  }

  Timer? _positionTimer;
  Future<void> _onStatusChanged(PlaybackStatus status) async {
    _updatePositionTimer();
  }

  void _updatePositionTimer() {
    _onPositionChanged();
    if (_audioHandler.playbackStatus.value == PlaybackStatus.playing &&
        syncedMode) {
      _startPositionTimer();
    } else {
      _stopPositionTimer();
    }
  }

  void _startPositionTimer() {
    if (_positionTimer != null) return;
    _positionTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _onPositionChanged(),
    );
  }

  void _stopPositionTimer() {
    bool wasOn = _positionTimer != null;
    _positionTimer?.cancel();
    _positionTimer = null;
    if (wasOn) {
      _onPositionChanged();
    }
  }

  void _onPositionChanged({bool force = false}) {
    if (lyrics == null) {
      if (_selectedLine.value != null || force) {
        _selectedLine.add(null);
      }
      return;
    }

    final pos = _audioHandler.position;
    final currentIndex = _selectedLine.value;
    final currentLine = currentIndex != null
        ? lyrics?.lines.elementAtOrNull(_selectedLine.value!)
        : null;
    if (!force &&
        currentLine != null &&
        currentLine.start != null &&
        currentLine.start! <= pos) {
      if ((currentLine.end != null && currentLine.end! > pos) ||
          currentIndex! == lyrics!.lines.length - 1) {
        // current line is still correct
        return;
      }
      _calculateCurrentLine(pos, currentIndex);
      return;
    }
    _calculateCurrentLine(pos, 0, force: force);
  }

  void _calculateCurrentLine(
    Duration pos,
    int startIndex, {
    bool force = false,
  }) {
    if (lyrics == null) {
      if (_selectedLine.value != null || force) {
        _selectedLine.add(null);
      }
      return;
    }

    int? found;
    for (int i = startIndex; i < lyrics!.lines.length; i++) {
      final line = lyrics!.lines[i];
      if (line.start == null) continue;
      if (line.start! > pos) break;
      if ((line.end != null && line.end! > pos) ||
          i == lyrics!.lines.length - 1) {
        found = i;
        break;
      }
    }
    if (_selectedLine.value != found || force) {
      _selectedLine.add(found);
    }
  }

  @override
  void dispose() {
    _currentSubscription?.cancel();
    _statusSubscription?.cancel();
    _stopPositionTimer();
    _updateWakelock(enable: false);
    super.dispose();
  }

  Future<void> _updateWakelock({bool? enable}) async {
    enable ??= syncedMode;
    final enabled = await WakelockPlus.enabled;
    if (enable == enabled) return;
    if (enable) {
      Log.debug("Enabling wakelock because user is viewing synced lyrics.");
    } else {
      Log.debug(
        "Disabling wakelock because user is no longer viewing synced lyrics.",
      );
    }
    await WakelockPlus.toggle(enable: enable);
  }

  Future<void> seek(Duration duration) async {
    final paused = _audioHandler.playbackStatus.value == PlaybackStatus.paused;
    await _audioHandler.seek(duration);
    if (paused) {
      await _audioHandler.play();
    }
    syncedMode = true;
  }
}
