import 'package:audioplayers/audioplayers.dart';
import 'package:crossonic/repositories/subsonic/subsonic.dart';
import 'package:crossonic/services/audio_player/audio_handler.dart';
import 'package:crossonic/services/audio_player/media_queue.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:smtc_windows/smtc_windows.dart';

class CrossonicAudioHandlerWindows implements CrossonicAudioHandler {
  final SubsonicRepository _subsonicRepository;
  final MediaQueue _queue = MediaQueue();
  final AudioPlayer _player = AudioPlayer();
  late final SMTCWindows _smtc;
  final BehaviorSubject<CrossonicPlaybackState> _playbackState =
      BehaviorSubject();

  CrossonicAudioHandlerWindows({
    required SubsonicRepository subsonicRepository,
  }) : _subsonicRepository = subsonicRepository {
    _playbackState.add(
        const CrossonicPlaybackState(status: CrossonicPlaybackStatus.idle));

    _smtc = SMTCWindows(
        config: const SMTCConfig(
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
          case PressedButton.play:
            await play();
          case PressedButton.pause:
            await pause();
          case PressedButton.stop:
            await stop();
          case PressedButton.next:
            await skipToNext();
          case PressedButton.previous:
            await skipToPrevious();
          default:
            break;
        }
      });
    });

    _player.onPlayerStateChanged.listen((event) {
      _playbackState.add(_playbackState.value.copyWith(
          status: switch (event) {
        PlayerState.completed => CrossonicPlaybackStatus.completed,
        PlayerState.disposed ||
        PlayerState.stopped =>
          CrossonicPlaybackStatus.idle,
        PlayerState.paused => CrossonicPlaybackStatus.paused,
        PlayerState.playing => CrossonicPlaybackStatus.playing,
      }));
      switch (event) {
        case PlayerState.completed || PlayerState.paused:
          _smtc.setPlaybackStatus(PlaybackStatus.Paused);
        case PlayerState.disposed || PlayerState.stopped:
          _smtc.setPlaybackStatus(PlaybackStatus.Stopped);
        case PlayerState.playing:
          _smtc.setPlaybackStatus(PlaybackStatus.Playing);
      }
    });

    _player.onPlayerComplete.listen((_) => skipToNext());

    _player.onPositionChanged.listen((event) {
      _playbackState.add(
        _playbackState.value.copyWith(position: event),
      );
      if (_queue.current.value != null) {
        _smtc.updateTimeline(PlaybackTimeline(
          startTimeMs: 0,
          endTimeMs: (_queue.current.value!.item.duration ?? 0) * 1000,
          positionMs: event.inMilliseconds,
          minSeekTimeMs: 0,
          maxSeekTimeMs: (_queue.current.value!.item.duration ?? 0) * 1000,
        ));
      }
    });

    _queue.current.listen((value) async {
      if (value == null) return;
      if (_playbackState.value.status != CrossonicPlaybackStatus.idle &&
          _playbackState.value.status != CrossonicPlaybackStatus.paused) {
        if (_playbackState.value.status == CrossonicPlaybackStatus.playing) {
          await _player.pause();
        }
        _player.play(UrlSource(
          (await _subsonicRepository.getStreamURL(songID: value.item.id))
              .toString(),
        ));
      } else {
        _player.setSourceUrl(
            (await _subsonicRepository.getStreamURL(songID: value.item.id))
                .toString());
      }
      if (!_smtc.enabled) {
        await _smtc.enableSmtc();
      }
      _smtc.updateMetadata(MusicMetadata(
        album: value.item.album,
        albumArtist: value.item.displayAlbumArtist,
        artist: value.item.artist,
        thumbnail: value.item.coverArt != null
            ? (await getCoverArtURL(value.item.coverArt!, 500)).toString()
            : null,
        title: value.item.title,
      ));
    });
  }

  @override
  BehaviorSubject<CrossonicPlaybackState> get crossonicPlaybackStatus =>
      _playbackState;

  @override
  Future<void> playPause() async {
    if (!crossonicPlaybackStatus.hasValue) return;
    if (crossonicPlaybackStatus.value.status ==
        CrossonicPlaybackStatus.playing) {
      return await pause();
    }
    if (mediaQueue.current.valueOrNull == null) return;
    return await play();
  }

  @override
  Future<void> pause() {
    return _player.pause();
  }

  @override
  Future<void> play() async {
    await _player.resume();
    if (_playbackState.value.status == CrossonicPlaybackStatus.idle) {
      await Future.delayed(const Duration(milliseconds: 200));
      await _player.resume();
    }
  }

  @override
  Future<void> seek(Duration position) {
    return _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    if (_queue.canAdvance) {
      _queue.advance();
      await Future.delayed(const Duration(milliseconds: 200));
      await play();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queue.canGoBack) {
      _queue.back();
      await Future.delayed(const Duration(milliseconds: 200));
      await play();
    }
  }

  @override
  Future<void> stop() async {
    _queue.clear();
    await _smtc.disableSmtc();
    return await _player.stop();
  }

  @override
  MediaQueue get mediaQueue => _queue;

  @override
  Future<Uri> getCoverArtURL(String id, [int? size]) async {
    return await _subsonicRepository.getCoverArtURL(coverArtID: id, size: size);
  }

  @override
  Future<void> dispose() {
    return _player.dispose();
  }
}
