/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/data/repositories/cover/cover_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/data/services/methodchannel/android_library_result.dart';
import 'package:crossonic/data/services/methodchannel/android_mediaitem.dart';
import 'package:crossonic/data/services/methodchannel/method_channel_service.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/foundation.dart';

class AndroidAutoRepository {
  final MethodChannelService _methodChannel;
  final PlaylistRepository _playlistRepo;
  final CoverRepository _coverRepository;
  final PlaybackManager _playbackManager;

  AndroidAutoRepository({
    required MethodChannelService methodChannel,
    required PlaylistRepository playlistRepo,
    required CoverRepository coverRepository,
    required PlaybackManager playbackManager,
  }) : _playlistRepo = playlistRepo,
       _methodChannel = methodChannel,
       _coverRepository = coverRepository,
       _playbackManager = playbackManager {
    if (kIsWeb || !Platform.isAndroid) return;
    _methodChannel.handleMethodCall("onGetChildren", _onGetChildren);
    _methodChannel.handleMethodCall("getCoverFile", _getCoverFile);
    _methodChannel.handleMethodCall("setMediaItem", _setMediaItem);
    _methodChannel.handleMethodCall("onSearch", _onSearch);
    _methodChannel.handleMethodCall("onGetSearchResult", _onGetSearchResult);
    _methodChannel.handleMethodCall("playFromSearch", _playFromSearch);
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
      _playbackManager.player.playOnNextMediaChange();
      await _playbackManager.queue.replace(songs);
      return;
    }

    if (id.startsWith("crossonic_queue:")) {
      final queueId = id.substring("crossonic_queue:".length);
      _playbackManager.player.playOnNextMediaChange();
      await _playbackManager.queue.switchQueue(queueId);
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
          AndroidMediaItem(
            id: "crossonic_queues",
            title: "Queues",
            playable: false,
            browsable: true,
            contentStyle: AndroidLibraryContentStyle.list,
          ),
        ],
      ).toMsgData();
    }

    if (parentId == "crossonic_playlists") {
      final result = await _playlistRepo.getPlaylists(
        limit: pageSize ?? 100,
        offset: pageSize != null && page != null ? page * pageSize : null,
        download: params.isOffline ? true : null,
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

    if (parentId == "crossonic_queues") {
      final result = await _playbackManager.queue.getQueues(
        limit: pageSize ?? 100,
        offset: pageSize != null && page != null ? page * pageSize : 0,
      );
      return AndroidLibraryResult(
        params: AndroidLibraryParams(isOffline: params.isOffline),
        mediaItems: result
            .map(
              (q) => AndroidMediaItem(
                id: "crossonic_queue:${q.id}",
                browsable: false,
                playable: true,
                title: q.name,
              ),
            )
            .toList(),
      ).toMsgData();
    }

    return const AndroidLibraryResult(mediaItems: []).toMsgData();
  }

  Future<Map<Object?, dynamic>> _onGetSearchResult(
    Map<Object?, dynamic>? args,
  ) async {
    String query = args!["query"];
    int? page = args["page"];
    int? pageSize = args["pageSize"];
    final params = AndroidLibraryParams.fromMsgData(args["params"]);

    final playlistResult = await _playlistRepo.getPlaylists(
      limit: pageSize ?? 100,
      offset: page != null && pageSize != null ? page * pageSize : null,
      orderBy: PlaylistOrderBy.alphabetical,
      query: query,
      download: params.isOffline ? true : null,
    );
    switch (playlistResult) {
      case Err():
        Log.error(
          "failed to get playlist search results for Android Auto",
          e: playlistResult.error,
        );
        return const AndroidLibraryResult(
          resultCode: AndroidLibraryResultCode.unknown,
        ).toMsgData();
      case Ok():
    }

    final queues = await _playbackManager.queue.getQueues(
      filter: query,
      limit: pageSize ?? 100,
      offset: page != null && pageSize != null ? page * pageSize : 0,
    );

    List<AndroidMediaItem> mediaItems = [
      ...playlistResult.value.map(
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
      ),
      ...queues.map(
        (q) => AndroidMediaItem(
          id: "crossonic_queue:${q.id}",
          browsable: false,
          playable: true,
          title: q.name,
        ),
      ),
    ];

    mediaItems.sort(
      (a, b) => a.title!.toLowerCase().compareTo(b.title!.toLowerCase()),
    );

    return AndroidLibraryResult(
      params: AndroidLibraryParams(isOffline: params.isOffline),
      mediaItems: mediaItems,
    ).toMsgData();
  }

  Future<dynamic> _onSearch(Map<Object?, dynamic>? args) async {
    String query = args!["query"];
    final params = AndroidLibraryParams.fromMsgData(args["params"]);

    final playlistResult = await _playlistRepo.countPlaylists(
      query: query,
      download: params.isOffline ? true : null,
    );
    switch (playlistResult) {
      case Err():
        Log.error(
          "failed to search playlists for Android Auto",
          e: playlistResult.error,
        );
        return const AndroidLibraryResult(
          resultCode: AndroidLibraryResultCode.unknown,
        ).toMsgData();
      case Ok():
    }

    final queues = await _playbackManager.queue.countQueues(filter: query);

    return playlistResult.value + queues;
  }

  Future<void> _playFromSearch(Map<Object?, dynamic>? args) async {
    if (args == null) return;
    final query = args["query"]! as String;
    final result = await _playlistRepo.getPlaylists(
      orderBy: PlaylistOrderBy.updated,
      limit: 1,
      offset: 0,
      query: query,
    );
    if (result is Err || result.tryValue!.isEmpty) {
      Log.error(
        "Failed to find playlist for playFromSearch from Android Auto",
        e: (result as Err).error,
      );
      return;
    }
    final playlistResult = await _playlistRepo.getPlaylist(
      result.tryValue!.first.id,
    );
    switch (playlistResult) {
      case Err():
        Log.error(
          "Failed to get playlist for Android Auto playFromSearch request",
          e: playlistResult.error,
        );
        return;
      case Ok():
    }

    final songs = playlistResult.value?.tracks ?? [];
    if (songs.isEmpty) return;
    songs.shuffle();
    _playbackManager.player.playOnNextMediaChange();
    await _playbackManager.queue.replace(songs);
    return;
  }

  void dispose() {
    _methodChannel.removeMethodCallHandler("onGetChildren");
    _methodChannel.removeMethodCallHandler("getCoverFile");
    _methodChannel.removeMethodCallHandler("setMediaItem");
    _methodChannel.removeMethodCallHandler("onSearch");
    _methodChannel.removeMethodCallHandler("onGetSearchResult");
    _methodChannel.removeMethodCallHandler("playFromSearch");
  }
}
