import 'dart:math';

import 'package:crossonic/features/album/state/album_cubit.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/services/audio_player/audio_handler.dart';
import 'package:crossonic/widgets/cover_art.dart';
import 'package:crossonic/widgets/song.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AlbumPage extends StatelessWidget {
  const AlbumPage({super.key, required this.albumID});

  final String albumID;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crossonic | Album'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push("/settings"),
          )
        ],
      ),
      body: BlocBuilder<AlbumCubit, AlbumState>(
        builder: (context, album) {
          if (album.id != albumID && album.status != FetchStatus.failure) {
            context.read<AlbumCubit>().updateID(albumID);
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          final audioHandler = context.read<CrossonicAudioHandler>();
          return switch (album.status) {
            FetchStatus.initial ||
            FetchStatus.loading ||
            FetchStatus.loadingMore =>
              const Center(child: CircularProgressIndicator.adaptive()),
            FetchStatus.failure => const Center(child: Icon(Icons.wifi_off)),
            FetchStatus.success => LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CoverArt(
                            size: min(constraints.maxHeight * 0.60,
                                constraints.maxWidth - 25),
                            resolution: const CoverResolution.extraLarge(),
                            coverID: album.coverID,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            album.name,
                            style:
                                Theme.of(context).textTheme.bodyLarge!.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 22,
                                    ),
                          ),
                          TextButton(
                            onPressed: () {
                              if (album.artistID != "") {
                                context.push("/home/artist/${album.artistID}");
                              }
                            },
                            child: Text(
                              album.artistName +
                                  (album.year > 0 ? ' • ${album.year}' : ''),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 15,
                                  ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 10),
                            child: SizedBox(
                              width: 100000,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.play_arrow),
                                      label: const Text('Play'),
                                      onPressed: () {
                                        audioHandler.playOnNextMediaChange();
                                        audioHandler.mediaQueue
                                            .replaceQueue(album.subsonicSongs);
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.playlist_play),
                                      label: const Text('Prio. Queue'),
                                      onPressed: () {
                                        audioHandler.mediaQueue
                                            .addAllToPriorityQueue(
                                                album.subsonicSongs);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                              'Added "${album.name}" to priority queue'),
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(
                                              milliseconds: 1250),
                                        ));
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      icon: const Icon(
                                          Icons.playlist_add_outlined),
                                      label: const Text('Queue'),
                                      onPressed: () {
                                        audioHandler.mediaQueue
                                            .addAll(album.subsonicSongs);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                              'Added "${album.name}" to queue'),
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(
                                              milliseconds: 1250),
                                        ));
                                      },
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Column(
                            children: List<Widget>.generate(
                                album.songs.length,
                                (i) => Song(
                                      song: album.subsonicSongs[i],
                                      leadingItem: SongLeadingItem.track,
                                      showGotoAlbum: false,
                                      onTap: () {
                                        audioHandler.playOnNextMediaChange();
                                        audioHandler.mediaQueue.replaceQueue(
                                            album.subsonicSongs, i);
                                      },
                                    )),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
          };
        },
      ),
    );
  }
}
