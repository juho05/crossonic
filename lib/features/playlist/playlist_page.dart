import 'dart:math';

import 'package:crossonic/features/playlist/state/playlist_cubit.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/services/audio_handler/audio_handler.dart';
import 'package:crossonic/widgets/app_bar.dart';
import 'package:crossonic/widgets/confirmation.dart';
import 'package:crossonic/widgets/cover_art.dart';
import 'package:crossonic/widgets/large_cover.dart';
import 'package:crossonic/widgets/song.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class PlaylistPage extends StatelessWidget {
  const PlaylistPage({super.key, required this.playlistID});

  final String playlistID;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PlaylistCubit(context.read<PlaylistRepository>(), playlistID),
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
                    return ReorderableListView.builder(
                      header: Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CoverArtWithMenu(
                              id: state.id,
                              name: state.name,
                              enablePlay: true,
                              enableShuffle: true,
                              enableQueue: true,
                              enablePlaylist: true,
                              enableToggleFavorite: false,
                              uploading:
                                  state.coverStatus == CoverStatus.uploading,
                              size: min(constraints.maxHeight * 0.60,
                                  constraints.maxWidth - 25),
                              resolution: const CoverResolution.extraLarge(),
                              coverID: state.coverID,
                              borderRadius: 10,
                              getSongs: () async => state.songs,
                              editing: state.reorderEnabled,
                              onEdit: () {
                                context.read<PlaylistCubit>().toggleReorder();
                              },
                              onChangePicture:
                                  context.read<PlaylistCubit>().setCover,
                              onRemovePicture: state.coverID != null ?
                                  context.read<PlaylistCubit>().removeCover : null,
                              onDelete: () async {
                                if (!(await ConfirmationDialog.show(context))) {
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
                                          "Deleted playlist '${state.name}'")));
                              },
                            ),
                            const SizedBox(height: 10),
                            Text(
                              state.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 22,
                                  ),
                            ),
                            Text(
                              "Songs: ${state.songCount}",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 15,
                                  ),
                            ),
                            Text(
                              "Duration: ${state.duration.toString().split(".")[0]}",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 15,
                                  ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 13, vertical: 10),
                              child: SizedBox(
                                width: 100000,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.play_arrow),
                                      label: const Text('Play'),
                                      onPressed: () async {
                                        audioHandler.playOnNextMediaChange();
                                        audioHandler.mediaQueue
                                            .replaceQueue(state.songs);
                                      },
                                    ),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.shuffle),
                                      label: const Text('Shuffle'),
                                      onPressed: () async {
                                        audioHandler.playOnNextMediaChange();
                                        audioHandler.mediaQueue.replaceQueue(
                                            List.from(state.songs)..shuffle());
                                      },
                                    ),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.playlist_play),
                                      label: const Text('Prio. Queue'),
                                      onPressed: () async {
                                        audioHandler.mediaQueue
                                            .addAllToPriorityQueue(state.songs);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                              'Added "${state.name}" to priority queue'),
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(
                                              milliseconds: 1250),
                                        ));
                                      },
                                    ),
                                    ElevatedButton.icon(
                                      icon: const Icon(
                                          Icons.playlist_add_outlined),
                                      label: const Text('Queue'),
                                      onPressed: () async {
                                        audioHandler.mediaQueue
                                            .addAll(state.songs);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                              'Added "${state.name}" to queue'),
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(
                                              milliseconds: 1250),
                                        ));
                                      },
                                    ),
                                    ElevatedButton.icon(
                                      icon: state.reorderEnabled
                                          ? const Icon(Icons.edit_off)
                                          : const Icon(Icons.edit),
                                      label: state.reorderEnabled
                                          ? const Text('Stop Edit')
                                          : const Text('Edit'),
                                      onPressed: () async {
                                        context
                                            .read<PlaylistCubit>()
                                            .toggleReorder();
                                      },
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      buildDefaultDragHandles: false,
                      restorationId: "playlist_song_list",
                      itemCount: state.songs.length,
                      itemBuilder: (context, i) => Song(
                        key: ValueKey(i),
                        reorderIndex: state.reorderEnabled ? i : null,
                        song: state.songs[i],
                        leadingItem: SongLeadingItem.cover,
                        showGotoAlbum: false,
                        onRemove: () {
                          context
                              .read<PlaylistRepository>()
                              .removeSongsFromPlaylist(
                                  state.id, [(i, state.songs[i])]);
                        },
                        onTap: () {
                          audioHandler.playOnNextMediaChange();
                          audioHandler.mediaQueue.replaceQueue(state.songs, i);
                        },
                      ),
                      onReorder: (int oldIndex, int newIndex) {
                        context
                            .read<PlaylistCubit>()
                            .reorder(oldIndex, newIndex);
                      },
                    );
                  },
                ),
            };
          },
        ),
      ),
    );
  }
}
