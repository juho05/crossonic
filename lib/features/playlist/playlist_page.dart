import 'dart:math';

import 'package:crossonic/components/collection_page.dart';
import 'package:crossonic/components/state/layout.dart';
import 'package:crossonic/features/playlist/state/playlist_cubit.dart';
import 'package:crossonic/features/playlist/state/playlist_download_status_cubit.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/services/audio_handler/audio_handler.dart';
import 'package:crossonic/components/app_bar.dart';
import 'package:crossonic/components/confirmation.dart';
import 'package:crossonic/components/cover_art.dart';
import 'package:crossonic/components/large_cover.dart';
import 'package:crossonic/components/song.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class PlaylistPage extends StatelessWidget {
  const PlaylistPage({super.key, required this.playlistID});

  final String playlistID;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              PlaylistCubit(context.read<PlaylistRepository>(), playlistID),
        ),
        BlocProvider(
          create: (context) => PlaylistDownloadStatusCubit(
              playlistID, context.read<PlaylistRepository>()),
        ),
      ],
      child: Scaffold(
        appBar: createAppBar(context, "Playlist"),
        body: BlocConsumer<PlaylistCubit, PlaylistState>(
          listener: (context, state) {
            if (state.coverStatus == CoverStatus.uploadFailed) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                    const SnackBar(content: Text("Failed to upload image")));
            } else if (state.coverStatus == CoverStatus.fileTooBig) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(
                    content: Text("Only files <= 15 MB are allowed")));
            }
          },
          builder: (context, state) {
            final audioHandler = context.read<CrossonicAudioHandler>();
            return switch (state.status) {
              FetchStatus.initial ||
              FetchStatus.loading =>
                const Center(child: CircularProgressIndicator.adaptive()),
              FetchStatus.failure => const Center(child: Icon(Icons.wifi_off)),
              FetchStatus.success => LayoutBuilder(
                  builder: (context, constraints) {
                    return BlocBuilder<PlaylistDownloadStatusCubit,
                            PlaylistDownloadStatusState>(
                        builder: (context, dState) {
                      return CollectionPage(
                        name: state.name,
                        contentTitle: "Tracks",
                        cover: LayoutBuilder(
                          builder: (context, constraints2) {
                            final layout = context.watch<Layout>();
                            return CoverArtWithMenu(
                              id: state.id,
                              name: state.name,
                              enablePlay: true,
                              enableShuffle: true,
                              enableQueue: true,
                              enablePlaylist: true,
                              enableToggleFavorite: false,
                              uploading:
                                  state.coverStatus == CoverStatus.uploading,
                              size: layout.size == LayoutSize.mobile
                                  ? min(constraints.maxHeight * 0.60,
                                      constraints.maxWidth - 24)
                                  : min(constraints2.maxWidth,
                                      MediaQuery.sizeOf(context).height * 0.5),
                              resolution: const CoverResolution.extraLarge(),
                              coverID: state.coverID,
                              borderRadius: 10,
                              getSongs: () async => state.songs,
                              editing: state.reorderEnabled,
                              downloadStatus: switch (state.downloadStatus) {
                                DownloadStatus.none => null,
                                DownloadStatus.downloading => false,
                                DownloadStatus.downloaded => true,
                              },
                              onToggleDownload: kIsWeb
                                  ? null
                                  : () {
                                      final repo =
                                          context.read<PlaylistRepository>();
                                      if (state.downloadStatus ==
                                          DownloadStatus.none) {
                                        repo.downloadPlaylist(state.id);
                                      } else {
                                        repo.removePlaylistDownload(state.id);
                                      }
                                    },
                              onEdit: () {
                                context.read<PlaylistCubit>().toggleReorder();
                              },
                              onChangePicture:
                                  context.read<PlaylistCubit>().setCover,
                              onRemovePicture: state.coverID != null
                                  ? context.read<PlaylistCubit>().removeCover
                                  : null,
                              onDelete: () async {
                                if (!(await ConfirmationDialog.showCancel(
                                    context))) {
                                  return;
                                }
                                if (!context.mounted) return;
                                await context
                                    .read<PlaylistRepository>()
                                    .delete(state.id);
                                if (!context.mounted) return;
                                context.pop();
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(SnackBar(
                                      content: Text(
                                          "Deleted playlist '//${state.name}'")));
                              },
                            );
                          },
                        ),
                        actions: [
                          CollectionAction(
                            title: "Play",
                            icon: Icons.play_arrow,
                            onClick: () {
                              audioHandler.playOnNextMediaChange();
                              audioHandler.mediaQueue.replaceQueue(state.songs);
                            },
                          ),
                          CollectionAction(
                            title: "Shuffle",
                            icon: Icons.shuffle,
                            onClick: () {
                              audioHandler.playOnNextMediaChange();
                              audioHandler.mediaQueue.replaceQueue(
                                  List.from(state.songs)..shuffle());
                            },
                          ),
                          CollectionAction(
                            title: 'Prio. Queue',
                            icon: Icons.playlist_play,
                            onClick: () async {
                              audioHandler.mediaQueue
                                  .addAllToPriorityQueue(state.songs);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(
                                    'Added "${state.name}" to priority queue'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(milliseconds: 1250),
                              ));
                            },
                          ),
                          CollectionAction(
                            title: 'Queue',
                            icon: Icons.playlist_add_outlined,
                            onClick: () async {
                              audioHandler.mediaQueue.addAll(state.songs);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text('Added "${state.name}" to queue'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(milliseconds: 1250),
                              ));
                            },
                          ),
                          CollectionAction(
                            title: state.reorderEnabled ? 'Stop Edit' : 'Edit',
                            icon: state.reorderEnabled
                                ? Icons.edit_off
                                : Icons.edit,
                            onClick: () async {
                              context.read<PlaylistCubit>().toggleReorder();
                            },
                          )
                        ],
                        extraInfo: [
                          CollectionExtraInfo(
                              text: "Songs: ${state.songCount}"),
                          CollectionExtraInfo(
                              text:
                                  "Duration: ${state.duration.toString().split(".")[0]}"),
                          if (state.downloadStatus ==
                              DownloadStatus.downloading)
                            CollectionExtraInfo(
                                text:
                                    "Downloading: ${dState.waiting ? "waiting" : '${dState.downloadedSongsCount}/${state.songCount}'}")
                        ],
                        reorderableItemCount: state.songs.length,
                        reorderableItemBuilder: (context, i) => Song(
                          key: ValueKey(i),
                          reorderIndex: state.reorderEnabled ? i : null,
                          song: state.songs[i],
                          leadingItem: SongLeadingItem.cover,
                          onRemove: () {
                            context
                                .read<PlaylistRepository>()
                                .removeSongsFromPlaylist(
                                    state.id, [(i, state.songs[i])]);
                          },
                          onTap: () {
                            audioHandler.playOnNextMediaChange();
                            audioHandler.mediaQueue
                                .replaceQueue(state.songs, i);
                          },
                        ),
                        onReorder: (int oldIndex, int newIndex) {
                          context
                              .read<PlaylistCubit>()
                              .reorder(oldIndex, newIndex);
                        },
                      );
                    });
                  },
                ),
            };
          },
        ),
      ),
    );
  }
}
