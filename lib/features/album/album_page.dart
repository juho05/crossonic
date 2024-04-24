import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:crossonic/features/album/state/album_cubit.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/services/audio_player/audio_handler.dart';
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
                          SizedBox(
                            height: min(constraints.maxHeight * 0.60,
                                constraints.maxWidth - 25),
                            width: min(constraints.maxHeight * 0.60,
                                constraints.maxWidth - 25),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              clipBehavior: Clip.antiAlias,
                              child: CachedNetworkImage(
                                  fit: BoxFit.cover,
                                  imageUrl: album.coverURL,
                                  useOldImageOnUrlChange: false,
                                  placeholder: (context, url) => Icon(
                                        Icons.album,
                                        opticalSize: constraints.maxHeight != 0
                                            ? min(constraints.maxHeight * 0.55,
                                                constraints.maxWidth - 35)
                                            : 100,
                                        size: constraints.maxHeight != 0
                                            ? min(constraints.maxHeight * 0.55,
                                                constraints.maxWidth - 35)
                                            : 100,
                                      ),
                                  fadeInDuration:
                                      const Duration(milliseconds: 300),
                                  fadeOutDuration:
                                      const Duration(milliseconds: 100),
                                  errorWidget: (context, url, error) {
                                    return Icon(
                                      Icons.album,
                                      opticalSize: constraints.maxHeight != 0
                                          ? min(constraints.maxHeight * 0.45,
                                              constraints.maxWidth - 35)
                                          : 100,
                                      size: constraints.maxHeight != 0
                                          ? min(constraints.maxHeight * 0.45,
                                              constraints.maxWidth - 35)
                                          : 100,
                                    );
                                  }),
                            ),
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
                          Text(
                            album.artistName +
                                (album.year > 0 ? ' • ${album.year}' : ''),
                            style:
                                Theme.of(context).textTheme.bodyLarge!.copyWith(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 15,
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
                                      id: album.songs[i].id,
                                      title: album.songs[i].title,
                                      track: album.songs[i].number,
                                      duration: album.songs[i].duration !=
                                              Duration.zero
                                          ? album.songs[i].duration
                                          : null,
                                      isFavorite: album.songs[i].isFavorite,
                                      // coverURL: album.coverURL,
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
