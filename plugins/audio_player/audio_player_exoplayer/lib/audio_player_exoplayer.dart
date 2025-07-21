import 'package:audio_player_platform_interface/audio_player_event.dart';
import 'package:audio_player_platform_interface/audio_player_platform_interface.dart';
import 'package:exoplayer/exoplayer.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerExoPlayer extends AudioPlayerPlatform {
  final ExoPlayer _player;

  static void registerWith() {
    AudioPlayerPlatform.instance = AudioPlayerExoPlayer();
  }

  AudioPlayerExoPlayer() : _player = ExoPlayer() {
    _player.advanceStream.listen((_) => _onAdvance());
    _player.stateStream.listen((state) => _onStateChange(state));
    _player.errorStream.listen((err) => _onPlatformError(err.$1, err.$2));
    _player.restartStream.listen((pos) {
      _restartPlayback.add(pos);
    });
  }

  @override
  Future<Duration> get position async => _player.position;

  @override
  Future<Duration> get bufferedPosition async => _player.bufferedPosition;

  final BehaviorSubject<AudioPlayerEvent> _eventStream = BehaviorSubject.seeded(
    AudioPlayerEvent.stopped,
  );

  @override
  ValueStream<AudioPlayerEvent> get eventStream => _eventStream.stream;

  Future<void> _onAdvance() async {
    _canSeek = _nextCanSeek;
    _nextCanSeek = false;
    _eventStream.add(AudioPlayerEvent.advance);
  }

  Future<void> _onStateChange(String platformState) async {
    final state = AudioPlayerEvent.values.byName(platformState);
    if (state == eventStream.value) return;
    switch (state) {
      case AudioPlayerEvent.stopped:
        _eventStream.add(AudioPlayerEvent.stopped);
      case AudioPlayerEvent.loading:
        _eventStream.add(AudioPlayerEvent.loading);
      case AudioPlayerEvent.paused:
        _eventStream.add(AudioPlayerEvent.paused);
      case AudioPlayerEvent.playing:
        _eventStream.add(AudioPlayerEvent.playing);
      case AudioPlayerEvent.advance:
        break;
    }
  }

  final BehaviorSubject<Duration> _restartPlayback = BehaviorSubject();
  @override
  ValueStream<Duration> get restartPlayback => _restartPlayback.stream;

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setCurrent(Uri url,
      {Uri? nextUrl, Duration pos = Duration.zero}) async {
    _canSeek = _canSeekFromUrl(url);
    _nextCanSeek = nextUrl != null && _canSeekFromUrl(nextUrl);
    await _player.setCurrent(url, nextUrl: nextUrl, pos: pos);
  }

  @override
  Future<void> setNext(Uri? url) async {
    if (!initialized) return;
    _nextCanSeek = url != null && _canSeekFromUrl(url);
    await _player.setNext(url);
  }

  @override
  Future<void> stop() async {
    if (!initialized) return;
    await _player.stop();
  }

  @override
  bool get supportsFileUri => true;

  bool _canSeek = false;
  bool _nextCanSeek = false;
  @override
  bool get canSeek => _canSeek;

  @override
  double get volume => _targetVolume;

  double _targetVolume = 1;

  @override
  Future<void> setVolume(double volume) async {
    volume = volume.clamp(0, 1);
    _targetVolume = volume;
    await _applyVolume();
  }

  Future<void> _applyVolume() async {
    await _player.setVolume(volume);
  }

  bool _initialized = false;
  @override
  bool get initialized => _initialized;

  @override
  Future<void> init() async {
    if (initialized) return;
    _player.ensureInitialized();
    await _player.init();
    _initialized = true;
  }

  @override
  Future<void> dispose() async {
    if (!initialized) return;
    await _player.dispose();
    _initialized = false;
  }

  Future<void> _onPlatformError(Object error, StackTrace stackTrace) async {
    throw error;
  }

  bool _canSeekFromUrl(Uri url) {
    return url.scheme == "file" ||
        (url.queryParameters.containsKey("format") &&
            url.queryParameters["format"] == "raw");
  }
}
