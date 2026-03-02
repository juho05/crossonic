import 'dart:io';

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

  AndroidAutoRepository({
    required MethodChannelService methodChannel,
    required SubsonicRepository subsonicRepo,
    required PlaylistRepository playlistRepo,
  }) : _subsonicRepo = subsonicRepo,
       _playlistRepo = playlistRepo,
       _methodChannel = methodChannel {
    if (kIsWeb || !Platform.isAndroid) return;
    _methodChannel.handleMethodCall("onGetChildren", _onGetChildren);
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
        params: AndroidLibraryParams(
          isOffline: params.isOffline,
          contentStyle: AndroidLibraryContentStyle.list,
        ),
        mediaItems: [
          AndroidMediaItem(
            id: "crossonic_playlists",
            title: "Playlists",
            playable: false,
            browsable: true,
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
        params: AndroidLibraryParams(
          isOffline: params.isOffline,
          contentStyle: AndroidLibraryContentStyle.list,
        ),
        mediaItems: result.value
            .where((p) => !params.isOffline || p.download)
            .map(
              (p) => AndroidMediaItem(
                id: "crossonic_playlist:${p.id}",
                browsable: false,
                playable: true,
                durationMs: p.duration.inMilliseconds,
                title: p.name,
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
