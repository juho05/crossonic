import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart' as asv;
import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/services/media_integration/media_integration.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/foundation.dart';

class AudioServiceIntegration extends asv.BaseAudioHandler
    with asv.SeekHandler
    implements MediaIntegration {
  final PlaylistRepository _playlistRepository;

  Future<void> Function()? _onPlay;
  Future<void> Function()? _onPause;
  Future<void> Function(Duration position)? _onSeek;
  Future<void> Function()? _onPlayNext;
  Future<void> Function()? _onPlayPrev;
  Future<void> Function()? _onStop;

  AudioHandler? _audioHandler;

  AudioServiceIntegration({
    required PlaylistRepository playlistRepository,
  }) : _playlistRepository = playlistRepository;

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
    if (_audioHandler != null) return;
    _audioHandler = audioHandler;
    _audioHandler!.queue.looping.listen((loop) {
      playbackState.add(playbackState.value.copyWith(
        repeatMode: _audioHandler!.queue.looping.value
            ? asv.AudioServiceRepeatMode.all
            : asv.AudioServiceRepeatMode.none,
      ));
    });
    _onPlay = onPlay;
    _onPause = onPause;
    _onSeek = onSeek;
    _onPlayNext = onPlayNext;
    _onPlayPrev = onPlayPrev;
    _onStop = onStop;
  }

  @override
  Future<List<asv.MediaItem>> getChildren(String parentMediaId,
      [Map<String, dynamic>? options]) async {
    if (parentMediaId == "root") {
      return [
        const asv.MediaItem(
            id: "playlists",
            title: "Playlists",
            playable: false,
            extras: {
              // DESCRIPTION_EXTRAS_KEY_CONTENT_STYLE_BROWSABLE: DESCRIPTION_EXTRAS_VALUE_CONTENT_STYLE_GRID_ITEM
              "android.media.browse.CONTENT_STYLE_BROWSABLE_HINT": 2,
            })
      ];
    }
    if (parentMediaId == "playlists") {
      final result = await _playlistRepository.getPlaylists();
      switch (result) {
        case Err():
          Log.error("Failed to get playlists", result.error);
          return [];
        case Ok():
      }
      return result.value
          .map((p) => asv.MediaItem(
                id: p.id,
                title: p.name,
                playable: false,
                displayDescription: "Songs: ${p.songCount}",
                artUri: _playlistRepository.getPlaylistCoverUri(p, size: 512),
              ))
          .toList();
    }
    return [
      asv.MediaItem(
        id: "playlist;play;$parentMediaId",
        title: "Play",
        playable: true,
      ),
      asv.MediaItem(
        id: "playlist;shuffle;$parentMediaId",
        title: "Shuffle",
        playable: true,
      ),
    ];
  }

  @override
  Future<void> playFromMediaId(String mediaId,
      [Map<String, dynamic>? extras]) async {
    if (mediaId.startsWith("playlist;")) {
      final parts = mediaId.split(";");
      final result = await _playlistRepository.getPlaylist(parts[2]);
      switch (result) {
        case Err():
          throw result.error;
        case Ok():
      }
      if (result.value == null) {
        throw Exception("playlist not found");
      }
      final songs = result.value!.tracks;
      if (parts[1] == "shuffle") {
        songs.shuffle();
      }
      _audioHandler?.playOnNextMediaChange();
      _audioHandler?.queue.replace(songs);
      return;
    }
  }

  @override
  Future<void> play() async {
    if (_audioHandler!.playbackStatus.value == PlaybackStatus.stopped) {
      playbackState.add(playbackState.value.copyWith(
        controls: [],
        systemActions: {},
        androidCompactActionIndices: [],
        processingState: asv.AudioProcessingState.idle,
        playing: false,
      ));
      return;
    }
    return _onPlay!();
  }

  @override
  Future<void> pause() async {
    await _onPause!();
  }

  @override
  Future<void> seek(Duration position) async {
    await _onSeek!(position);
  }

  @override
  Future<void> skipToNext() async {
    await _onPlayNext!();
  }

  @override
  Future<void> skipToPrevious() async {
    await _onPlayPrev!();
  }

  @override
  Future<void> stop() async {
    await _onStop!();
  }

  @override
  void updateMedia(Song? song, Uri? coverArt) {
    if (song == null) {
      if (!kIsWeb && Platform.isAndroid) {
        mediaItem.add(const asv.MediaItem(id: "", title: "No media"));
      } else {
        mediaItem.add(null);
      }
      playbackState.add(playbackState.value.copyWith(
        controls: [],
        systemActions: {},
        androidCompactActionIndices: [],
        processingState: asv.AudioProcessingState.idle,
        playing: false,
      ));
    } else {
      if (playbackState.value.controls.isEmpty) {
        playbackState.add(playbackState.value.copyWith(
          controls: [
            asv.MediaControl.pause,
            asv.MediaControl.play,
            asv.MediaControl.skipToNext,
            asv.MediaControl.skipToPrevious,
            asv.MediaControl.stop,
          ],
          systemActions: {
            asv.MediaAction.pause,
            asv.MediaAction.play,
            asv.MediaAction.playPause,
            asv.MediaAction.seek,
            asv.MediaAction.seekForward,
            asv.MediaAction.seekBackward,
            asv.MediaAction.skipToNext,
            asv.MediaAction.skipToPrevious,
            asv.MediaAction.stop,
            asv.MediaAction.setRepeatMode,
          },
          androidCompactActionIndices: [0, 1],
          repeatMode: _audioHandler!.queue.looping.value
              ? asv.AudioServiceRepeatMode.all
              : asv.AudioServiceRepeatMode.none,
        ));
      }
      mediaItem.add(asv.MediaItem(
        id: song.id,
        title: song.title,
        album: song.album?.name,
        artUri: coverArt,
        artist: song.displayArtist,
        duration: song.duration,
        genre: song.genres.firstOrNull,
        playable: true,
      ));
    }
  }

  @override
  void updatePlaybackState(PlaybackStatus status) {
    switch (status) {
      case PlaybackStatus.playing:
        playbackState.add(playbackState.value.copyWith(
            playing: true, processingState: asv.AudioProcessingState.ready));
      case PlaybackStatus.paused:
        playbackState.add(playbackState.value.copyWith(
            playing: false, processingState: asv.AudioProcessingState.ready));
      case PlaybackStatus.loading:
        playbackState.add(playbackState.value.copyWith(
            playing: false, processingState: asv.AudioProcessingState.loading));
      case PlaybackStatus.stopped:
        playbackState.add(playbackState.value.copyWith(
            playing: false, processingState: asv.AudioProcessingState.idle));
    }
  }

  @override
  void updatePosition(Duration position,
      [Duration bufferedPosition = Duration.zero]) {
    playbackState.add(playbackState.value.copyWith(
      updatePosition: position,
      bufferedPosition: bufferedPosition,
    ));
  }

  @override
  Future<void> onTaskRemoved() async {
    if (_onStop == null) return;
    if (playbackState.value.playing) return;
    await _onStop!();
  }

  @override
  Future<void> onNotificationDeleted() async {
    if (_onStop == null) return;
    await _onStop!();
  }

  @override
  Future<void> setRepeatMode(asv.AudioServiceRepeatMode repeatMode) async {
    _audioHandler!.queue.setLoop(repeatMode != asv.AudioServiceRepeatMode.none);
  }
}
