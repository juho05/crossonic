import 'dart:async';

import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/subsonic/models/lyrics.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

class LyricsViewModel extends ChangeNotifier {
  final SubsonicRepository _subsonic;
  final AudioHandler _audioHandler;
  StreamSubscription? _currentSubscription;
  StreamSubscription? _statusSubscription;

  bool get supportsSync => _lyrics?.synced ?? false;

  bool _syncedMode = false;
  bool get syncedMode => _syncedMode && supportsSync;

  set syncedMode(bool sync) {
    _syncedMode = sync;
    notifyListeners();
  }

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  Song? _currentSong;
  Song? get currentSong => _currentSong;

  Lyrics? _lyrics;
  Lyrics? get lyrics => _lyrics;

  final BehaviorSubject<Duration> _position = BehaviorSubject.seeded(
    Duration.zero,
  );
  ValueStream<Duration> get position => _position.stream;

  bool get playing =>
      _audioHandler.playbackStatus.value == PlaybackStatus.playing;

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
    notifyListeners();
  }

  Timer? _positionTimer;
  Future<void> _onStatusChanged(PlaybackStatus status) async {
    notifyListeners();
    if (status == PlaybackStatus.playing) {
      _positionTimer ??= Timer.periodic(
        const Duration(milliseconds: 250),
        (_) => _position.add(_audioHandler.position),
      );
    } else {
      _positionTimer?.cancel();
      _positionTimer = null;
    }
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _positionTimer = null;
    _currentSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }

  void seek(Duration pos) {
    _audioHandler.seek(pos);
  }
}
