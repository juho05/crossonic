import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:crossonic/repositories/api/models/media_model.dart';
import 'package:crossonic/services/audio_handler/players/player.dart';
import 'package:gstreamer/gstreamer.dart' as gst;
import 'package:rxdart/rxdart.dart';

class AudioPlayerGstreamer implements CrossonicAudioPlayer {
  @override
  bool canSeek = false;
  bool _nextCanSeek = false;

  String? _nextURL;

  AudioPlayerEvent _desiredState = AudioPlayerEvent.stopped;
  gst.State _gstState = gst.State.initial;
  bool _buffering = false;

  bool _newStreamStart = false;

  final AudioSession _audioSession;

  AudioPlayerGstreamer(AudioSession audioSession)
      : _audioSession = audioSession {
    _audioSession.interruptionEventStream.listen((event) async {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _ducking = true;
            _applyVolume();
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            await pause();
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _ducking = false;
            _applyVolume();
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            await play();
            break;
        }
      }
    });

    _audioSession.becomingNoisyEventStream.listen((_) async {
      await pause();
    });
  }

  Timer? _debounce;
  @override
  void init() async {
    gst.init(
      onStateChanged: (oldState, newState) async {
        _gstState = newState;

        if (_buffering || _desiredState == AudioPlayerEvent.stopped) return;

        if (newState == gst.State.playing) {
          _debounce?.cancel();
          _debounce = null;
          eventStream.add(AudioPlayerEvent.playing);
        } else if (newState == gst.State.paused &&
            _desiredState == AudioPlayerEvent.paused) {
          _debounce?.cancel();
          _debounce = null;
          eventStream.add(AudioPlayerEvent.paused);
        } else {
          if (_debounce?.isActive ?? false) _debounce?.cancel();
          _debounce = Timer(const Duration(seconds: 5), () {
            eventStream.add(AudioPlayerEvent.loading);
          });
        }
      },
      onEOS: () {
        if (_nextURL == null) {
          eventStream.add(AudioPlayerEvent.stopped);
        }
      },
      onStreamStart: () {
        if (_newStreamStart) {
          _newStreamStart = false;
          return;
        }
        _nextURL = null;
        canSeek = _nextCanSeek;
        _nextCanSeek = false;
        eventStream.add(AudioPlayerEvent.advance);
      },
      onError: (code, message, debugInfo) {
        print("ERROR: Gstreamer: $message\n$debugInfo");
      },
      onWarning: (code, message) {
        print("WARNING: Gstreamer: $message");
      },
      onBuffering: (percent, mode, avgIn, avgOut) {
        if (percent < 100) {
          _eventStream.add(AudioPlayerEvent.loading);
          _buffering = true;
          gst.setState(gst.State.paused);
        } else {
          _buffering = false;
          if (_desiredState == AudioPlayerEvent.paused &&
              _gstState == gst.State.paused) {
            _eventStream.add(AudioPlayerEvent.paused);
          }
          _activateDesiredState();
        }
      },
      onAboutToFinish: () {
        if (_nextURL != null) {
          gst.setUrl(_nextURL!);
          _nextURL = null;
        }
      },
    );
  }

  Future<void> _activateDesiredState() async {
    switch (_desiredState) {
      case AudioPlayerEvent.playing:
        await _audioSession.setActive(true);
        gst.setState(gst.State.playing);
        break;
      case AudioPlayerEvent.paused:
      case AudioPlayerEvent.stopped:
        gst.setState(gst.State.paused);
        await _audioSession.setActive(false);
        break;
      default:
        break;
    }
  }

  @override
  Future<void> dispose() async {
    gst.freeResources();
    _debounce?.cancel();
    _gstState = gst.State.initial;
  }

  @override
  Future<void> pause() async {
    _desiredState = AudioPlayerEvent.paused;
    await _activateDesiredState();
  }

  @override
  Future<void> play() async {
    _desiredState = AudioPlayerEvent.playing;
    await _activateDesiredState();
  }

  @override
  Future<void> seek(Duration position) async {
    gst.seek(position);
  }

  @override
  Future<void> stop() async {
    _buffering = false;
    _eventStream.add(AudioPlayerEvent.stopped);
    _desiredState = AudioPlayerEvent.stopped;
    await _activateDesiredState();
  }

  @override
  Future<Duration> get position async => gst.getPosition();

  @override
  Future<Duration> get bufferedPosition async => Duration.zero;

  final BehaviorSubject<AudioPlayerEvent> _eventStream =
      BehaviorSubject.seeded(AudioPlayerEvent.stopped);
  @override
  BehaviorSubject<AudioPlayerEvent> get eventStream => _eventStream;

  @override
  Future<void> setCurrent(Media media, Uri url) async {
    _newStreamStart = true;
    _buffering = true;
    eventStream.add(AudioPlayerEvent.loading);
    gst.setState(gst.State.ready);
    gst.setUrl(url.toString());
    await _activateDesiredState();
    canSeek = url.scheme == "file" ||
        (url.queryParameters.containsKey("format") &&
            url.queryParameters["format"] == "raw");
  }

  @override
  Future<void> setNext(Media? media, Uri? url) async {
    _nextURL = url?.toString();
    if (url != null) {
      _nextCanSeek = url.scheme == "file" ||
          (url.queryParameters.containsKey("format") &&
              url.queryParameters["format"] == "raw");
    } else {
      _nextCanSeek = false;
    }
  }

  @override
  bool get supportsFileURLs => true;

  double _targetVolume = 1;
  bool _ducking = false;

  @override
  Future<void> setVolume(double volume) async {
    // gstreamer volume element supports up to 1000%
    volume = volume.clamp(0, 10);
    _targetVolume = volume;
    _applyVolume();
  }

  void _applyVolume() {
    if (_ducking) {
      gst.setVolume(_targetVolume * 0.5);
    } else {
      gst.setVolume(_targetVolume);
    }
  }

  @override
  double get volume => _targetVolume;
}
