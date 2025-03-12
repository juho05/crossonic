import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/services/media_integration/media_integration.dart';
import 'package:flutter/material.dart';
import 'package:smtc_windows/smtc_windows.dart' as smtc;

class SMTCIntegration implements MediaIntegration {
  bool _initialized = false;
  late final smtc.SMTCWindows _smtc;

  @override
  Future<void> ensureInitialized({
    required AudioHandler audioHandler,
    required Future<void> Function() onPlay,
    required Future<void> Function() onPause,
    required Future<void> Function(Duration position) onSeek,
    required Future<void> Function() onPlayNext,
    required Future<void> Function() onPlayPrev,
    required Future<void> Function() onStop,
  }) async {
    if (_initialized) return;
    _initialized = true;

    await smtc.SMTCWindows.initialize();

    _smtc = smtc.SMTCWindows(
        enabled: true,
        config: const smtc.SMTCConfig(
          fastForwardEnabled: true,
          nextEnabled: true,
          pauseEnabled: true,
          playEnabled: true,
          rewindEnabled: true,
          prevEnabled: true,
          stopEnabled: true,
        ));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _smtc.buttonPressStream.listen((event) async {
        switch (event) {
          case smtc.PressedButton.play:
            await onPlay();
          case smtc.PressedButton.pause:
            await onPause();
          case smtc.PressedButton.stop:
            await onStop();
          case smtc.PressedButton.next:
            await onPlayNext();
          case smtc.PressedButton.previous:
            await onPlayPrev();
          default:
            break;
        }
      });
    });
  }

  @override
  void updateMedia(Song? song, Uri? coverArt) {
    if (song == null) {
      _smtc.clearMetadata();
    } else {
      _smtc.updateMetadata(smtc.MusicMetadata(
        album: song.album?.name,
        artist: song.displayArtist,
        thumbnail: coverArt?.toString(),
        title: song.title,
      ));
    }
  }

  @override
  void updatePlaybackState(PlaybackStatus status) {
    switch (status) {
      case PlaybackStatus.playing:
        _smtc.setPlaybackStatus(smtc.PlaybackStatus.playing);
      case PlaybackStatus.paused:
        _smtc.setPlaybackStatus(smtc.PlaybackStatus.paused);
      case PlaybackStatus.stopped:
        _smtc.setPlaybackStatus(smtc.PlaybackStatus.stopped);
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
