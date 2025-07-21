import 'dart:async';

import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/foundation.dart';

class LyricsViewModel extends ChangeNotifier {
  final SubsonicRepository _subsonic;
  final AudioHandler _audioHandler;
  StreamSubscription? _currentSubscription;

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  Song? _currentSong;
  Song? get currentSong => _currentSong;

  List<String> _lyrics = [];
  List<String> get lyrics => _lyrics;

  LyricsViewModel({
    required SubsonicRepository subsonic,
    required AudioHandler audioHandler,
  })  : _subsonic = subsonic,
        _audioHandler = audioHandler {
    _currentSubscription = _audioHandler.queue.current.listen((current) {
      _currentSong = current;
      _fetch();
    });
  }

  Future<void> _fetch() async {
    _lyrics = [];
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

  @override
  void dispose() {
    _currentSubscription?.cancel();
    super.dispose();
  }
}
