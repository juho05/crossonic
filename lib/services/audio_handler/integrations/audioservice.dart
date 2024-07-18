import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:crossonic/repositories/api/models/media_model.dart';
import 'package:crossonic/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/services/audio_handler/audio_handler.dart';
import 'package:crossonic/services/audio_handler/integrations/integration.dart';
import 'package:flutter/foundation.dart';

class AudioServiceIntegration extends BaseAudioHandler
    with SeekHandler
    implements NativeIntegration {
  Future<void> Function()? _onPlay;
  Future<void> Function()? _onPause;
  Future<void> Function(Duration position)? _onSeek;
  Future<void> Function()? _onPlayNext;
  Future<void> Function()? _onPlayPrev;
  Future<void> Function()? _onStop;

  final APIRepository _apiRepository;
  final PlaylistRepository _playlistRepository;
  CrossonicAudioHandler? _audioHandler;

  AudioServiceIntegration({
    required APIRepository apiRepository,
    required PlaylistRepository playlistRepository,
  })  : _apiRepository = apiRepository,
        _playlistRepository = playlistRepository;

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
    if (_audioHandler != null) return;
    _audioHandler = audioHandler;
    _audioHandler!.mediaQueue.loop.listen((value) {
      playbackState.add(playbackState.value.copyWith(
        repeatMode: _audioHandler!.mediaQueue.loop.value
            ? AudioServiceRepeatMode.all
            : AudioServiceRepeatMode.none,
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
  Future<List<MediaItem>> getChildren(String parentMediaId,
      [Map<String, dynamic>? options]) async {
    if (parentMediaId == "root") {
      return [
        const MediaItem(
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
      final playlists = _playlistRepository.playlists.value;
      return playlists
          .map((p) => MediaItem(
                id: p.id,
                title: p.name,
                playable: false,
                displayDescription: "Songs: ${p.songCount}",
                artUri: p.coverArt != null
                    ? _apiRepository.getCoverArtURL(coverArtID: p.coverArt!)
                    : null,
              ))
          .toList();
    }
    return [
      MediaItem(
        id: "playlist;play;$parentMediaId",
        title: "Play",
        playable: true,
      ),
      MediaItem(
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
      final playlist = await _playlistRepository.getUpdatedPlaylist(parts[2]);
      final List<Media> songs;
      if (parts[1] == "play") {
        songs = playlist.entry ?? [];
      } else if (parts[1] == "shuffle") {
        songs = List<Media>.from(playlist.entry ?? [])..shuffle();
      } else {
        songs = [];
      }
      _audioHandler!.playOnNextMediaChange();
      _audioHandler!.mediaQueue.replaceQueue(songs);
      return;
    }
  }

  @override
  Future<void> play() async {
    if (_audioHandler!.crossonicPlaybackStatus.value.status ==
        CrossonicPlaybackStatus.stopped) {
      playbackState.add(playbackState.value.copyWith(
        controls: [],
        systemActions: {},
        androidCompactActionIndices: [],
        processingState: AudioProcessingState.idle,
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
  void updateMedia(Media? media, Uri? coverArt) {
    if (media == null) {
      if (!kIsWeb && Platform.isAndroid) {
        mediaItem.add(const MediaItem(id: "", title: "No media"));
      } else {
        mediaItem.add(null);
      }
      playbackState.add(playbackState.value.copyWith(
        controls: [],
        systemActions: {},
        androidCompactActionIndices: [],
        processingState: AudioProcessingState.idle,
        playing: false,
      ));
    } else {
      if (playbackState.value.controls.isEmpty) {
        playbackState.add(playbackState.value.copyWith(
          controls: [
            MediaControl.pause,
            MediaControl.play,
            MediaControl.skipToNext,
            MediaControl.skipToPrevious,
            MediaControl.stop,
          ],
          systemActions: {
            MediaAction.pause,
            MediaAction.play,
            MediaAction.playPause,
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
            MediaAction.skipToNext,
            MediaAction.skipToPrevious,
            MediaAction.stop,
            MediaAction.setRepeatMode,
          },
          androidCompactActionIndices: [0, 1],
          repeatMode: _audioHandler!.mediaQueue.loop.value
              ? AudioServiceRepeatMode.all
              : AudioServiceRepeatMode.none,
        ));
      }
      mediaItem.add(MediaItem(
        id: media.id,
        title: media.title,
        album: media.album,
        artUri: coverArt,
        artist: media.artist,
        duration:
            media.duration != null ? Duration(seconds: media.duration!) : null,
        genre: media.genre,
        playable: true,
      ));
    }
  }

  @override
  void updatePlaybackState(CrossonicPlaybackStatus status) {
    switch (status) {
      case CrossonicPlaybackStatus.playing:
        playbackState.add(playbackState.value.copyWith(
            playing: true, processingState: AudioProcessingState.ready));
      case CrossonicPlaybackStatus.paused:
        playbackState.add(playbackState.value.copyWith(
            playing: false, processingState: AudioProcessingState.ready));
      case CrossonicPlaybackStatus.loading:
        playbackState.add(playbackState.value.copyWith(
            playing: false, processingState: AudioProcessingState.loading));
      case CrossonicPlaybackStatus.stopped:
        playbackState.add(playbackState.value.copyWith(
            playing: false, processingState: AudioProcessingState.idle));
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
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    _audioHandler!.mediaQueue
        .setLoop(repeatMode != AudioServiceRepeatMode.none);
  }
}
