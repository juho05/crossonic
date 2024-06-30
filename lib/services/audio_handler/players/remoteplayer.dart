import 'package:crossonic/repositories/api/models/media_model.dart';
import 'package:crossonic/services/audio_handler/players/player.dart';
import 'package:crossonic/services/connect/connect_manager.dart';
import 'package:crossonic/services/connect/models/device.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerRemote implements CrossonicAudioPlayer {
  final Device _device;
  final ConnectManager _manager;

  bool _playing = false;

  Duration _lastPosition = Duration.zero;
  DateTime _lastPositionTime = DateTime.now();

  final BehaviorSubject<AudioPlayerEvent> _eventStream =
      BehaviorSubject.seeded(AudioPlayerEvent.loading);

  Media? _current;
  Media? _next;

  bool _stopRequested = false;

  AudioPlayerRemote(Device device, ConnectManager manager)
      : _device = device,
        _manager = manager {
    _manager.speakerState.listen((value) async {
      if (value == null) return;
      var state = AudioPlayerEvent.values.byName(value.state);
      if (state == AudioPlayerEvent.stopped &&
          _eventStream.value == AudioPlayerEvent.loading &&
          !_stopRequested &&
          _current != null) {
        if (_current!.duration == null ||
            _current!.duration! - (await position).inSeconds > 5) {
          state = AudioPlayerEvent.loading;
          await _manager.sendSpeakerSetCurrent(
              _device.id, _current!.id, _next?.id, await position);
          if (_playing) {
            await play();
          }
        }
      }
      _lastPositionTime = DateTime.now();
      _lastPosition = Duration(milliseconds: value.positionMs);
      _eventStream.add(state);
    });
    _eventStream.listen((state) {
      _playing = state == AudioPlayerEvent.playing;
      switch (state) {
        case AudioPlayerEvent.stopped:
          _current = null;
          _next = null;
        case AudioPlayerEvent.advance:
          _current = _next;
          _next = null;
        default:
      }
    });
  }

  @override
  Future<void> setCurrent(Media media, Uri url) async {
    _current = media;
    _stopRequested = false;
    Duration timeOffset =
        Duration(seconds: int.parse(url.queryParameters["timeOffset"] ?? "0"));
    await _manager.sendSpeakerSetCurrent(
        _device.id, media.id, _next?.id, timeOffset);
  }

  @override
  Future<void> setNext(Media? media, Uri? url) async {
    _next = media;
    await _manager.sendSpeakerSetNext(_device.id, media?.id);
  }

  @override
  Future<void> seek(Duration position) async {
    throw Exception("not implemented");
  }

  @override
  Future<void> play() async {
    await _manager.sendPlay(_device.id);
  }

  @override
  Future<void> pause() async {
    await _manager.sendPause(_device.id);
  }

  @override
  Future<void> stop() async {
    _stopRequested = true;
    await _manager.sendStop(_device.id);
  }

  @override
  Future<Duration> get position async =>
      _lastPosition +
      (_playing ? DateTime.now().difference(_lastPositionTime) : Duration.zero);

  @override
  Future<Duration> get bufferedPosition async => Duration.zero;

  @override
  BehaviorSubject<AudioPlayerEvent> get eventStream => _eventStream;

  @override
  Future<void> dispose() async {
    await stop();
  }

  @override
  bool get supportsFileURLs => false;
  @override
  bool get canSeek => false;
}
