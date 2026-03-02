import 'dart:io';

import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/cover/cover_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/data/services/methodchannel/android_library_result.dart';
import 'package:crossonic/data/services/methodchannel/android_mediaitem.dart';
import 'package:crossonic/data/services/methodchannel/method_channel_service.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/foundation.dart';

class AndroidAutoRepository {
  final MethodChannelService _methodChannel;
  final SubsonicRepository _subsonicRepo;
  final PlaylistRepository _playlistRepo;
  final CoverRepository _coverRepository;
  final AudioHandler _audioHandler;

  AndroidAutoRepository({
    required MethodChannelService methodChannel,
    required SubsonicRepository subsonicRepo,
    required PlaylistRepository playlistRepo,
    required CoverRepository coverRepository,
    required AudioHandler audioHandler,
  }) : _subsonicRepo = subsonicRepo,
       _playlistRepo = playlistRepo,
       _methodChannel = methodChannel,
       _coverRepository = coverRepository,
       _audioHandler = audioHandler {
    if (kIsWeb || !Platform.isAndroid) return;
    _methodChannel.handleMethodCall("onGetChildren", _onGetChildren);
    _methodChannel.handleMethodCall("getCoverFile", _getCoverFile);
    _methodChannel.handleMethodCall("setMediaItem", _setMediaItem);
  }

  Future<void> _setMediaItem(Map<Object?, dynamic>? args) async {
    if (args == null) return;
    final id = args["id"]! as String;
    final posMs = args["startPositionMs"] as int?;

    if (id.startsWith("crossonic_playlist:")) {
      final pId = id.substring("crossonic_playlist:".length);
      final result = await _playlistRepo.getPlaylist(pId);
      switch (result) {
        case Err():
          Log.error(
            "Failed to get playlist for Android Auto play request",
            e: result.error,
          );
          return;
        case Ok():
      }
      final songs = result.value?.tracks ?? [];
      if (songs.isEmpty) return;
      songs.shuffle();
      _audioHandler.playOnNextMediaChange();
      _audioHandler.queue.replace(songs);
      return;
    }

    return;
  }

  Future<String?> _getCoverFile(String? coverId) async {
    if (coverId == null) return null;
    try {
      final file = await _coverRepository.getSingleFile(
        CoverRepository.getKey(coverId, 512),
      );
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<Map<Object?, dynamic>> _onGetChildren(
    Map<Object?, dynamic>? args,
  ) async {
    String parentId = args!["parentId"];
    int? page = args["page"];
    int? pageSize = args["pageSize"];
    final params = AndroidLibraryParams.fromMsgData(args["params"]);

    if (parentId == "crossonic_root") {
      return AndroidLibraryResult(
        params: AndroidLibraryParams(isOffline: params.isOffline),
        mediaItems: [
          AndroidMediaItem(
            id: "crossonic_playlists",
            title: "Playlists",
            playable: false,
            browsable: true,
            contentStyle: AndroidLibraryContentStyle.grid,
          ),
        ],
      ).toMsgData();
    }

    if (parentId == "crossonic_playlists") {
      final result = await _playlistRepo.getPlaylists(
        limit: pageSize,
        offset: pageSize != null && page != null ? page * pageSize : null,
      );
      switch (result) {
        case Err():
          Log.error(
            "failed to get playlists for Android Auto",
            e: result.error,
          );
          return const AndroidLibraryResult(
            resultCode: AndroidLibraryResultCode.unknown,
          ).toMsgData();
        case Ok():
      }
      return AndroidLibraryResult(
        params: AndroidLibraryParams(isOffline: params.isOffline),
        mediaItems: result.value
            .where((p) => !params.isOffline || p.download)
            .map(
              (p) => AndroidMediaItem(
                id: "crossonic_playlist:${p.id}",
                browsable: false,
                playable: true,
                durationMs: p.duration.inMilliseconds,
                title: p.name,
                artworkContentUri: p.coverId != null
                    ? Uri(
                        scheme: "content",
                        host: kDebugMode
                            ? "org.crossonic.app.debug.covers"
                            : "org.crossonic.app.covers",
                        pathSegments: [p.coverId!],
                      )
                    : null,
              ),
            )
            .toList(),
      ).toMsgData();
    }

    return const AndroidLibraryResult(mediaItems: []).toMsgData();
  }

  void dispose() {
    _methodChannel.removeMethodCallHandler("onGetChildren");
  }
}
