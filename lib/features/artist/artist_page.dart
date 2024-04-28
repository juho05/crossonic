import 'dart:math';

import 'package:crossonic/features/album/state/album_cubit.dart';
import 'package:crossonic/features/artist/state/artist_cubit.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/subsonic/models/media_model.dart';
import 'package:crossonic/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/services/audio_player/audio_handler.dart';
import 'package:crossonic/widgets/album.dart';
import 'package:crossonic/widgets/cover_art.dart';
import 'package:crossonic/widgets/song.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ArtistPage extends StatelessWidget {
  const ArtistPage({super.key, required this.artistID});

  final String artistID;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crossonic | Artist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push("/settings"),
          )
        ],
      ),
      body: BlocBuilder<ArtistCubit, ArtistState>(
        builder: (context, artist) {
          if (artist.id != artistID && artist.status != FetchStatus.failure) {
            context.read<ArtistCubit>().updateID(artistID);
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          final audioHandler = context.read<CrossonicAudioHandler>();
          final subsonicRepository = context.read<SubsonicRepository>();
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          return switch (artist.status) {
            FetchStatus.initial ||
            FetchStatus.loading =>
              const Center(child: CircularProgressIndicator.adaptive()),
            FetchStatus.failure => const Center(child: Icon(Icons.wifi_off)),
            FetchStatus.success => LayoutBuilder(
                builder: (context, constraints) {
                  final theme = Theme.of(context);
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      child: Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CoverArt(
                              size: min(constraints.maxHeight * 0.60,
                                  constraints.maxWidth - 25),
                              resolution: const CoverResolution.extraLarge(),
                              coverID: artist.coverID,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              artist.name,
                              style: theme.textTheme.bodyLarge!.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 22,
                              ),
                            ),
                            Text(
                              artist.genres.isNotEmpty
                                  ? artist.genres
                                      .sublist(0, min(3, artist.genres.length))
                                      .join(", ")
                                  : "Unknown genre",
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 15,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: 100000,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.play_arrow),
                                      label: const Text('Play'),
                                      onPressed: () {
                                        doSomethingWithArtistSongs(
                                          albums: artist.albums,
                                          repository: subsonicRepository,
                                          scaffoldMessenger: scaffoldMessenger,
                                          callback: (songs) {
                                            audioHandler
                                                .playOnNextMediaChange();
                                            audioHandler.mediaQueue
                                                .replaceQueue(songs);
                                          },
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.playlist_play),
                                      label: const Text('Prio. Queue'),
                                      onPressed: () {
                                        doSomethingWithArtistSongs(
                                          albums: artist.albums,
                                          repository: subsonicRepository,
                                          scaffoldMessenger: scaffoldMessenger,
                                          successMessage:
                                              "Added '${artist.name} to priority queue",
                                          callback: (songs) {
                                            audioHandler.mediaQueue
                                                .addAllToPriorityQueue(songs);
                                          },
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      icon: const Icon(
                                          Icons.playlist_add_outlined),
                                      label: const Text('Queue'),
                                      onPressed: () {
                                        doSomethingWithArtistSongs(
                                          albums: artist.albums,
                                          repository: subsonicRepository,
                                          scaffoldMessenger: scaffoldMessenger,
                                          successMessage:
                                              "Added '${artist.name} to queue",
                                          callback: (songs) {
                                            audioHandler.mediaQueue
                                                .addAll(songs);
                                          },
                                        );
                                      },
                                    )
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  "Albums (${artist.albums.length})",
                                  style: theme.textTheme.headlineSmall!
                                      .copyWith(fontSize: 20),
                                ),
                                const SizedBox(height: 10),
                                LayoutBuilder(builder: (context, constraints) {
                                  return Column(
                                    crossAxisAlignment:
                                        constraints.maxWidth > 500
                                            ? CrossAxisAlignment.stretch
                                            : CrossAxisAlignment.center,
                                    children: [
                                      Wrap(
                                        spacing: constraints.maxWidth <= 462 &&
                                                constraints.maxWidth > 380
                                            ? 30
                                            : 15,
                                        runSpacing: 12,
                                        alignment: WrapAlignment.start,
                                        children: List<Widget>.generate(
                                            artist.albums.length,
                                            (i) => SizedBox(
                                                  height: 180,
                                                  child: Album(
                                                    id: artist.albums[i].id,
                                                    name: artist.albums[i].name,
                                                    coverID: artist
                                                        .albums[i].coverID,
                                                    extraInfo: artist.albums[i]
                                                                .year !=
                                                            null
                                                        ? "${artist.albums[i].year}"
                                                        : "Unknown year",
                                                  ),
                                                )),
                                      ),
                                    ],
                                  );
                                })
                              ],
                            )
                          ],
                        ),
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

  Future<void> doSomethingWithArtistSongs({
    required List<ArtistAlbum> albums,
    required void Function(List<Media>) callback,
    required SubsonicRepository repository,
    required ScaffoldMessengerState scaffoldMessenger,
    String? successMessage,
  }) async {
    try {
      final songLists = await Future.wait((albums).map((a) async {
        final album = await repository.getAlbum(a.id);
        return album.song ?? <Media>[];
      }));
      callback(songLists.expand((s) => s).toList());
      if (successMessage != null) {
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(successMessage),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1250),
        ));
      }
    } catch (e) {
      print(e);
      scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('An unexpected error occured'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1250),
      ));
    }
  }
}
