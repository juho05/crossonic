import 'package:crossonic/repositories/api/models/media_model.dart';
import 'package:crossonic/services/audio_handler/audio_handler.dart';
import 'package:crossonic/services/audio_handler/integrations/integration.dart';
import 'package:flutter/material.dart';
import 'package:smtc_windows/smtc_windows.dart';

class SMTCIntegration implements NativeIntegration {
  bool _initialized = false;
  late final SMTCWindows _smtc;

  SMTCIntegration() {
    _smtc = SMTCWindows(
        enabled: true,
        config: const SMTCConfig(
          fastForwardEnabled: true,
          nextEnabled: true,
          pauseEnabled: true,
          playEnabled: true,
          rewindEnabled: true,
          prevEnabled: true,
          stopEnabled: true,
        ));
  }

  @override
  void ensureInitialized({
    required CrossonicAudioHandler audioHandler,
    required Future<void> Function() onPlay,
    required Future<void> Function() onPause,
    required Future<void> Function(Duration position) onSeek,
    required Future<void> Function() onPlayNext,
    required Future<void> Function() onPlayPrev,
    required Future<void> Function() onStop,
  }) {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _smtc.buttonPressStream.listen((event) async {
        switch (event) {
          case PressedButton.play:
            await onPlay();
          case PressedButton.pause:
            await onPause();
          case PressedButton.stop:
            await onStop();
          case PressedButton.next:
            await onPlayNext();
          case PressedButton.previous:
            await onPlayPrev();
          default:
            break;
        }
      });
    });
  }

  @override
  void updateMedia(Media? media, Uri? coverArt) {
    if (media == null) {
      _smtc.clearMetadata();
    } else {
      _smtc.updateMetadata(MusicMetadata(
        album: media.album,
        albumArtist: media.displayAlbumArtist,
        artist: media.artist,
        thumbnail: coverArt?.toString(),
        title: media.title,
      ));
    }
  }

  @override
  void updatePlaybackState(CrossonicPlaybackStatus status) {
    switch (status) {
      case CrossonicPlaybackStatus.playing:
        _smtc.setPlaybackStatus(PlaybackStatus.playing);
      case CrossonicPlaybackStatus.paused:
        _smtc.setPlaybackStatus(PlaybackStatus.paused);
      case CrossonicPlaybackStatus.stopped:
        _smtc.setPlaybackStatus(PlaybackStatus.stopped);
      default:
        break;
    }
  }

  @override
  void updatePosition(Duration position,
      [Duration bufferedPosition = Duration.zero]) {
    // is displayed nowhere and causes bugs when called repeatedly
  }
}
