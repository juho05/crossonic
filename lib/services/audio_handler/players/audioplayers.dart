import 'dart:async';
import 'package:crossonic/repositories/api/models/media_model.dart';
import 'package:crossonic/services/audio_handler/players/player.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerAudioPlayers implements CrossonicAudioPlayer {
  final List<AudioPlayer> _players = [AudioPlayer(), AudioPlayer()];
  int _currentPlayer = 0;

  Media? _currentMedia;

  String? _nextURL;
  String? _nextPlayerURL;

  Timer? _positionTimer;

  @override
  bool canSeek = false;
  bool _nextCanSeek = false;

  AudioPlayerAudioPlayers() {
    for (var i = 0; i < _players.length; i++) {
      _players[i].onPlayerComplete.listen((_) async {
        if (i != _currentPlayer) {
          _players[i].pause();
          return;
        }
        if (_nextURL != null) {
          if (_nextPlayerURL == _nextURL) {
            final oldPlayer = _currentPlayer;
            _currentPlayer = _nextPlayerIndex;
            _players[oldPlayer].release();
            await play();
          } else {
            await _players[_currentPlayer].setSourceUrl(_nextURL.toString());
          }
          _nextPlayerURL = null;
          _nextURL = null;
          canSeek = _nextCanSeek;
          _nextCanSeek = false;
          _eventStream.add(AudioPlayerEvent.advance);
        } else {
          _eventStream.add(AudioPlayerEvent.stopped);
        }
      });
      _players[i].onPlayerStateChanged.listen((state) {
        if (i != _currentPlayer) {
          return;
        }
        if (state == PlayerState.playing) {
          _startPositionTimer();
          _eventStream.add(AudioPlayerEvent.playing);
        } else {
          _stopPositionTimer();
        }
        if (state == PlayerState.paused &&
            _eventStream.value != AudioPlayerEvent.stopped) {
          _eventStream.add(AudioPlayerEvent.paused);
        }
      });
    }
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
    if (_currentMedia != null) {
      if (_currentMedia!.duration != null &&
          _currentMedia!.duration! - pos.inSeconds < 10) {
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
    _currentMedia = null;
    _nextURL = null;
    _nextPlayerURL = null;
    for (var i = 0; i < _players.length; i++) {
      await _players[i].release();
    }
    _eventStream.add(AudioPlayerEvent.stopped);
  }

  @override
  Future<void> dispose() async {
    _stopPositionTimer();
    await stop();
    for (var i = 0; i < _players.length; i++) {
      await _players[i].dispose();
    }
  }

  @override
  Future<Duration> get position async =>
      await _players[_currentPlayer].getCurrentPosition() ?? Duration.zero;

  @override
  Future<Duration> get bufferedPosition async => Duration.zero;

  final BehaviorSubject<AudioPlayerEvent> _eventStream =
      BehaviorSubject.seeded(AudioPlayerEvent.stopped);
  @override
  BehaviorSubject<AudioPlayerEvent> get eventStream => _eventStream;

  @override
  Future<void> setCurrent(Media media, Uri url) async {
    _eventStream.add(AudioPlayerEvent.loading);
    await _players[_currentPlayer].setSourceUrl(url.toString());
    canSeek = url.queryParameters.containsKey("format") &&
        url.queryParameters["format"] == "raw";
    _nextURL = null;
    _nextPlayerURL = null;
    _currentMedia = media;
  }

  @override
  Future<void> setNext(Media? media, Uri? url) async {
    _nextURL = url.toString();
    if (url != null) {
      _nextCanSeek = url.queryParameters.containsKey("format") &&
          url.queryParameters["format"] == "raw";
    } else {
      _nextCanSeek = false;
    }
  }

  @override
  bool get supportsFileURLs => false;
}
