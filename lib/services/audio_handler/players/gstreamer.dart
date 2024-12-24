import 'dart:async';
import 'dart:math';

import 'package:audio_session/audio_session.dart';
import 'package:crossonic/repositories/api/models/media_model.dart';
import 'package:crossonic/services/audio_handler/players/player.dart';
import 'package:gstreamer/gstreamer.dart' as gst;
import 'package:rxdart/rxdart.dart';

class AudioPlayerGstreamer implements CrossonicAudioPlayer {
  @override
  bool canSeek = false;
  bool _nextCanSeek = false;

  double _volume = 1;

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
            _setVolume(_volume * 0.5);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            await pause();
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _setVolume(min(_volume * 2, 1));
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

  @override
  void init() async {
    Timer? debounce;
    gst.init(
      onStateChanged: (oldState, newState) {
        _gstState = newState;
        if (_buffering || _desiredState == AudioPlayerEvent.stopped) return;
        if (debounce?.isActive ?? false) debounce?.cancel();

        debounce = Timer(const Duration(milliseconds: 25), () async {
          if (newState == gst.State.playing) {
            if (!await _audioSession.setActive(true)) {
              gst.setState(gst.State.paused);
            }
          } else {
            await _audioSession.setActive(false);
          }
          if (newState == gst.State.playing) {
            eventStream.add(AudioPlayerEvent.playing);
          } else if (newState == gst.State.paused &&
              _desiredState == AudioPlayerEvent.paused) {
            eventStream.add(AudioPlayerEvent.paused);
          } else {
            eventStream.add(AudioPlayerEvent.loading);
          }
        });
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
      onEOS: () => eventStream.add(AudioPlayerEvent.stopped),
      onError: (code, message, debugInfo) {
        print("ERROR: Gstreamer: $message\n$debugInfo");
      },
      onWarning: (code, message) {
        print("WARNING: Gstreamer: $message");
      },
      onBuffering: (percent, mode, avgIn, avgOut) {
        if (percent < 100) {
          if (_eventStream.value != AudioPlayerEvent.loading) {
            _eventStream.add(AudioPlayerEvent.loading);
          }
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

  void _setVolume(double volume) {
    gst.setVolume(volume);
    _volume = volume;
  }

  void _activateDesiredState() {
    switch (_desiredState) {
      case AudioPlayerEvent.playing:
        gst.setState(gst.State.playing);
        break;
      case AudioPlayerEvent.paused:
      case AudioPlayerEvent.stopped:
        gst.setState(gst.State.paused);
        break;
      default:
        break;
    }
  }

  @override
  Future<void> dispose() async {
    gst.freeResources();
  }

  @override
  Future<void> pause() async {
    _desiredState = AudioPlayerEvent.paused;
    _activateDesiredState();
  }

  @override
  Future<void> play() async {
    _desiredState = AudioPlayerEvent.playing;
    _activateDesiredState();
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
    _activateDesiredState();
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
    _activateDesiredState();
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
}
