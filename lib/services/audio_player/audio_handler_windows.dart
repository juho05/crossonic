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
  final List<AudioPlayer> _players = [AudioPlayer(), AudioPlayer()];
  int _currentPlayer = 0;

  late final SMTCWindows _smtc;
  final BehaviorSubject<CrossonicPlaybackState> _playbackState =
      BehaviorSubject();

  String? _nextURL;
  String? _nextPlayerURL;
  var _playOnNextMediaChange = false;

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
          case PressedButton.play || PressedButton.pause:
            await playPause();
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

    for (var i = 0; i < _players.length; i++) {
      _players[i].onPlayerComplete.listen((_) async {
        if (i != _currentPlayer) {
          _players[i].pause();
          return;
        }

        if (mediaQueue.canAdvance) {
          await skipToNext();
        } else {
          await stop();
        }
      });
    }

    for (var i = 0; i < _players.length; i++) {
      _players[i].onPositionChanged.listen((pos) async {
        if (i != _currentPlayer) {
          return;
        }
        _playbackState.add(
          _playbackState.value.copyWith(position: pos),
        );
        if (_queue.current.value != null) {
          _smtc.updateTimeline(PlaybackTimeline(
            startTimeMs: 0,
            endTimeMs: (_queue.current.value!.item.duration ?? 0) * 1000,
            positionMs: pos.inMilliseconds,
            minSeekTimeMs: 0,
            maxSeekTimeMs: (_queue.current.value!.item.duration ?? 0) * 1000,
          ));

          if (_queue.current.value!.item.duration != null &&
              _queue.current.value!.item.duration! - pos.inSeconds < 8 &&
              _nextURL != null &&
              _nextPlayerURL != _nextURL) {
            _nextPlayerURL = _nextURL;
            await _players[_nextPlayerIndex()].setSourceUrl(_nextURL!);
          }
        }
      });
      _players[i].onPlayerStateChanged.listen((state) {
        if (i != _currentPlayer) {
          return;
        }
        if (state == PlayerState.playing &&
            _playbackState.value.status != CrossonicPlaybackStatus.playing) {
          _playbackState.add(_playbackState.value
              .copyWith(status: CrossonicPlaybackStatus.playing));
        }
        if (state == PlayerState.paused &&
            _playbackState.value.status == CrossonicPlaybackStatus.playing) {
          _playbackState.add(_playbackState.value
              .copyWith(status: CrossonicPlaybackStatus.paused));
        }
      });
    }

    _queue.current.listen((value) async {
      CrossonicPlaybackStatus status = _playbackState.value.status;
      if (value == null) {
        if (status != CrossonicPlaybackStatus.idle) {
          stop();
        }
        return;
      }

      await _smtc.enableSmtc();
      _smtc.updateMetadata(MusicMetadata(
        album: value.item.album,
        albumArtist: value.item.displayAlbumArtist,
        artist: value.item.artist,
        thumbnail: value.item.coverArt != null
            ? (await getCoverArtURL(value.item.coverArt!, 500)).toString()
            : null,
        title: value.item.title,
      ));

      _playbackState.add(const CrossonicPlaybackState(
          status: CrossonicPlaybackStatus.loading, position: Duration.zero));

      final oldPlayer = _currentPlayer;
      _currentPlayer = _nextPlayerIndex();

      final streamURL =
          (await _subsonicRepository.getStreamURL(songID: value.item.id))
              .toString();

      _players[oldPlayer].release();
      if (!value.fromNext ||
          _nextPlayerURL == null ||
          _nextPlayerURL != _nextURL) {
        await _players[_currentPlayer].setSourceUrl(streamURL);
        await Future.delayed(const Duration(milliseconds: 250));
      }
      _nextPlayerURL = null;

      if (status == CrossonicPlaybackStatus.playing || _playOnNextMediaChange) {
        await play();
      } else {
        _playbackState.add(const CrossonicPlaybackState(
            status: CrossonicPlaybackStatus.paused));
      }
      _playOnNextMediaChange = false;

      if (value.next != null) {
        _nextURL =
            (await _subsonicRepository.getStreamURL(songID: value.next!.id))
                .toString();
      } else {
        _nextURL = null;
      }
    });
  }

  int _nextPlayerIndex() {
    var next = _currentPlayer + 1;
    if (next >= _players.length) {
      next = 0;
    }
    return next;
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
  Future<void> pause() async {
    if (_playbackState.value.status != CrossonicPlaybackStatus.playing) return;
    await _players[_currentPlayer].pause();
    _playbackState.add(
        _playbackState.value.copyWith(status: CrossonicPlaybackStatus.paused));
  }

  @override
  Future<void> play() async {
    if (_queue.current.value == null) return;
    await _players[_currentPlayer].resume();
    _playbackState.add(
        _playbackState.value.copyWith(status: CrossonicPlaybackStatus.playing));
  }

  @override
  Future<void> seek(Duration position) async {
    if (_playbackState.value.status == CrossonicPlaybackStatus.idle ||
        _playbackState.value.status == CrossonicPlaybackStatus.loading) return;
    return await _players[_currentPlayer].seek(position);
  }

  @override
  Future<void> skipToNext() async {
    if (_queue.canAdvance) {
      playOnNextMediaChange();
      _queue.advance();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queue.canGoBack) {
      playOnNextMediaChange();
      _queue.back();
    }
  }

  @override
  Future<void> stop() async {
    _playbackState.add(
        const CrossonicPlaybackState(status: CrossonicPlaybackStatus.idle));
    _queue.clear();
    await _smtc.disableSmtc();
    _nextURL = null;
    _nextPlayerURL = null;
    for (var i = 0; i < _players.length; i++) {
      await _players[i].release();
    }
  }

  @override
  MediaQueue get mediaQueue => _queue;

  @override
  Future<Uri> getCoverArtURL(String id, [int? size]) async {
    return await _subsonicRepository.getCoverArtURL(coverArtID: id, size: size);
  }

  @override
  Future<void> dispose() async {
    for (var i = 0; i < _players.length; i++) {
      await _players[i].dispose();
    }
  }

  @override
  void playOnNextMediaChange() {
    _playOnNextMediaChange = true;
  }
}
