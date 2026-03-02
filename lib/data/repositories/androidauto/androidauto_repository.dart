import 'dart:io';

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

  AndroidAutoRepository({
    required MethodChannelService methodChannel,
    required SubsonicRepository subsonicRepo,
    required PlaylistRepository playlistRepo,
    required CoverRepository coverRepository,
  }) : _subsonicRepo = subsonicRepo,
       _playlistRepo = playlistRepo,
       _methodChannel = methodChannel,
       _coverRepository = coverRepository {
    if (kIsWeb || !Platform.isAndroid) return;
    _methodChannel.handleMethodCall("onGetChildren", _onGetChildren);
    _methodChannel.handleMethodCall("getCoverFile", _getCoverFile);
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
