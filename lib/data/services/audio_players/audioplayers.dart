import 'dart:async';

import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:crossonic/data/services/audio_players/player.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerAudioPlayers implements AudioPlayer {
  final List<ap.AudioPlayer> _players = [];
  int _currentPlayer = 0;

  String? _nextURL;
  String? _nextPlayerURL;

  Timer? _positionTimer;

  @override
  bool canSeek = false;
  bool _nextCanSeek = false;

  AudioPlayerAudioPlayers();

  Duration? _currentDuration;

  bool _initialized = false;
  @override
  bool get initialized => _initialized;

  final List<StreamSubscription> _playerSubscriptions = [];

  @override
  Future<void> init() async {
    _players.clear();
    for (var s in _playerSubscriptions) {
      s.cancel();
    }
    _playerSubscriptions.clear();
    for (var i = 0; i < 2; i++) {
      _players.add(ap.AudioPlayer());
      _playerSubscriptions.add(_players[i]
          .onDurationChanged
          .debounceTime(Duration(seconds: 5))
          .listen((duration) {
        if (i != _currentPlayer) return;
        _currentDuration = duration;
      }));
      _playerSubscriptions.add(_players[i].onPlayerComplete.listen((_) async {
        if (i != _currentPlayer) {
          _players[i].pause();
          return;
        }
        if (_nextURL != null) {
          _currentDuration = null;
          if (_nextPlayerURL == _nextURL) {
            final oldPlayer = _currentPlayer;
            _currentPlayer = _nextPlayerIndex;
            _players[oldPlayer].release();
            await play();
          } else {
            await _players[_currentPlayer].setSourceUrl(_nextURL.toString());
            await play();
          }
          _nextPlayerURL = null;
          _nextURL = null;
          canSeek = _nextCanSeek;
          _nextCanSeek = false;
          _eventStream.add(AudioPlayerEvent.advance);
        } else {
          _eventStream.add(AudioPlayerEvent.stopped);
        }
      }));
      _playerSubscriptions.add(_players[i].onPlayerStateChanged.listen((state) {
        if (i != _currentPlayer) {
          return;
        }
        if (state == ap.PlayerState.playing) {
          _startPositionTimer();
          _eventStream.add(AudioPlayerEvent.playing);
        } else {
          _stopPositionTimer();
        }
        if (state == ap.PlayerState.paused &&
            _eventStream.value != AudioPlayerEvent.stopped) {
          _eventStream.add(AudioPlayerEvent.paused);
        }
      }));
    }
    _initialized = true;
  }

  int get _nextPlayerIndex {
    var next = _currentPlayer + 1;
    if (next >= _players.length) {
      next = 0;
    }
    return next;
  }

  void _startPositionTimer() {
    if (_positionTimer != null) return;
    _positionTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final pos = await _players[_currentPlayer].getCurrentPosition();
      if (pos != null) {
        _updatePosition(pos);
      }
    });
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  void _updatePosition(Duration pos) async {
    if (_currentDuration != null) {
      if (_currentDuration! - pos < Duration(seconds: 10)) {
        if (_nextURL != null && _nextPlayerURL != _nextURL) {
          _nextPlayerURL = _nextURL;
          await _players[_nextPlayerIndex].setSourceUrl(_nextURL!);
        }
      }
    }
  }

  @override
  Future<void> pause() async {
    await _players[_currentPlayer].pause();
    _eventStream.add(AudioPlayerEvent.paused);
  }

  @override
  Future<void> play() async {
    await _players[_currentPlayer].resume();
    _eventStream.add(AudioPlayerEvent.playing);
  }

  @override
  Future<void> seek(Duration position) async {
    if (!canSeek) return;
    await _players[_currentPlayer].seek(position);
    _updatePosition(position);
  }

  @override
  Future<void> stop() async {
    _currentDuration = null;
    _nextURL = null;
    _nextPlayerURL = null;
    for (var i = 0; i < _players.length; i++) {
      await _players[i].release();
    }
    _eventStream.add(AudioPlayerEvent.stopped);
  }

  @override
  Future<void> dispose() async {
    _initialized = false;
    _stopPositionTimer();
    await stop();
    for (var i = 0; i < _players.length; i++) {
      await _players[i].dispose();
    }
    _players.clear();
    for (var s in _playerSubscriptions) {
      await s.cancel();
    }
    _nextPlayerURL = null;
    _nextURL = null;
    _playerSubscriptions.clear();
  }

  @override
  Future<Duration> get position async =>
      await _players[_currentPlayer].getCurrentPosition() ?? Duration.zero;

  @override
  Future<Duration> get bufferedPosition async => Duration.zero;

  final BehaviorSubject<AudioPlayerEvent> _eventStream =
      BehaviorSubject.seeded(AudioPlayerEvent.stopped);
  @override
  ValueStream<AudioPlayerEvent> get eventStream => _eventStream.stream;

  @override
  Future<void> setCurrent(Uri url, [Duration? pos]) async {
    final shouldPlay = _eventStream.value == AudioPlayerEvent.playing;
    _eventStream.add(AudioPlayerEvent.loading);
    _currentDuration = null;
    canSeek = url.queryParameters.containsKey("format") &&
        url.queryParameters["format"] == "raw";
    await _players[_currentPlayer].setSourceUrl(url.toString());
    if (pos != null) {
      _players[_currentPlayer].seek(pos);
    }
    if (shouldPlay) {
      await play();
    } else {
      _eventStream.add(AudioPlayerEvent.paused);
    }
  }

  @override
  Future<void> setNext(Uri? url) async {
    _nextURL = url.toString();
    if (_nextPlayerURL != _nextURL) {
      _nextPlayerURL = null;
    }
    if (url != null) {
      _nextCanSeek = url.queryParameters.containsKey("format") &&
          url.queryParameters["format"] == "raw";
    } else {
      _nextCanSeek = false;
    }
  }

  @override
  bool get supportsFileUri => false;

  double _volume = 1;

  @override
  double get volume {
    return _volume;
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0, 1);
    List<Future<void>> futures = [];
    for (var p in _players) {
      futures.add(p.setVolume(_volume));
    }
    await futures.wait;
  }
}
