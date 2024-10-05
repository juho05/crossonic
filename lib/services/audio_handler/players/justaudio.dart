import 'dart:async';

import 'package:crossonic/repositories/api/api.dart';
import 'package:crossonic/services/audio_handler/players/player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerJustAudio implements CrossonicAudioPlayer {
  final AudioPlayer _player = AudioPlayer();
  ConcatenatingAudioSource? _playlist;
  int _currentPlayerPlaylistIndex = 0;

  Uri? _nextURL;

  @override
  bool canSeek = false;
  bool _nextCanSeek = false;

  AudioPlayerJustAudio() {
    _player.playerStateStream.listen((event) async {
      if (event.processingState == ProcessingState.completed) {
        _eventStream.add(AudioPlayerEvent.stopped);
      } else if (event.processingState == ProcessingState.buffering ||
          event.processingState == ProcessingState.loading) {
        _eventStream.add(AudioPlayerEvent.loading);
      } else if (event.playing) {
        _eventStream.add(AudioPlayerEvent.playing);
      } else if (!event.playing &&
          _eventStream.value != AudioPlayerEvent.stopped) {
        _eventStream.add(AudioPlayerEvent.paused);
      } else {
        _eventStream.add(AudioPlayerEvent.stopped);
      }
    });

    _player.currentIndexStream.listen((index) {
      if (index == null || index <= _currentPlayerPlaylistIndex) return;
      _currentPlayerPlaylistIndex = index;
      _nextURL = null;
      canSeek = _nextCanSeek;
      _nextCanSeek = false;
      _eventStream.add(AudioPlayerEvent.advance);
    });
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> play() async {
    _player.play();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> stop() async {
    _eventStream.add(AudioPlayerEvent.stopped);
    await _player.stop();
    if (_eventStream.value != AudioPlayerEvent.stopped) {
      await stop();
    }
    _playlist?.clear();
    _playlist = null;
    _currentPlayerPlaylistIndex = 0;
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }

  @override
  Future<Duration> get position async => _player.position;

  @override
  Future<Duration> get bufferedPosition async => _player.bufferedPosition;

  final BehaviorSubject<AudioPlayerEvent> _eventStream =
      BehaviorSubject.seeded(AudioPlayerEvent.stopped);
  @override
  BehaviorSubject<AudioPlayerEvent> get eventStream => _eventStream;

  @override
  Future<void> setCurrent(Media media, Uri url) async {
    _eventStream.add(AudioPlayerEvent.loading);
    _playlist?.clear();
    _currentPlayerPlaylistIndex = 0;
    _playlist = ConcatenatingAudioSource(children: [
      AudioSource.uri(url),
      if (_nextURL != null) AudioSource.uri(_nextURL!),
    ]);
    await _player.setAudioSource(_playlist!);
    canSeek = url.scheme == "file" ||
        (url.queryParameters.containsKey("format") &&
            url.queryParameters["format"] == "raw");
  }

  @override
  Future<void> setNext(Media? media, Uri? url) async {
    if (_currentPlayerPlaylistIndex + 1 < _playlist!.length) {
      _playlist!.removeAt(_currentPlayerPlaylistIndex + 1);
    }
    if (url != null) {
      _playlist!.add(AudioSource.uri(url));
    }
    _nextURL = url;
    if (url != null) {
      _nextCanSeek = url.scheme == "file" ||
          (url.queryParameters.containsKey("format") &&
              url.queryParameters["format"] == "raw");
    } else {
      _nextCanSeek = false;
    }
  }

  @override
  bool get supportsFileURLs => false;
}
