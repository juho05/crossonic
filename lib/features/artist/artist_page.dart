import 'dart:math';

import 'package:crossonic/components/collection_page.dart';
import 'package:crossonic/components/state/layout.dart';
import 'package:crossonic/features/artist/state/artist_cubit.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/api/models/media_model.dart';
import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:crossonic/services/audio_handler/audio_handler.dart';
import 'package:crossonic/components/album.dart';
import 'package:crossonic/components/app_bar.dart';
import 'package:crossonic/components/chooser.dart';
import 'package:crossonic/components/cover_art.dart';
import 'package:crossonic/components/large_cover.dart';
import 'package:crossonic/components/state/favorites_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ArtistPage extends StatelessWidget {
  const ArtistPage({super.key, required this.artistID});

  final String artistID;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ArtistCubit(context.read<APIRepository>())..load(artistID),
      child: Scaffold(
        appBar: createAppBar(context, "Artist"),
        body: BlocBuilder<ArtistCubit, ArtistState>(
          builder: (context, artist) {
            final audioHandler = context.read<CrossonicAudioHandler>();
            final apiRepository = context.read<APIRepository>();
            return switch (artist.status) {
              FetchStatus.initial ||
              FetchStatus.loading =>
                const Center(child: CircularProgressIndicator.adaptive()),
              FetchStatus.failure => const Center(child: Icon(Icons.wifi_off)),
              FetchStatus.success => LayoutBuilder(
                  builder: (context, constraints) {
                    return CollectionPage(
                      name: artist.name,
                      contentTitle: "Albums (${artist.albumCount})",
                      showContentTitleInMobileView: true,
                      cover: BlocBuilder<FavoritesCubit, FavoritesState>(
                        buildWhen: (previous, current) =>
                            current.changedId == artist.id,
                        builder: (context, state) {
                          final isFavorite =
                              state.favorites.contains(artist.id);
                          return LayoutBuilder(
                            builder: (context, constraints2) {
                              final layout = context.watch<Layout>();
                              return CoverArtWithMenu(
                                id: artist.id,
                                name: artist.name,
                                enablePlay: true,
                                enableShuffle: true,
                                enableQueue: true,
                                size: layout.size == LayoutSize.mobile
                                    ? min(constraints.maxHeight * 0.60,
                                        constraints.maxWidth - 24)
                                    : min(
                                        constraints2.maxWidth,
                                        MediaQuery.sizeOf(context).height *
                                            0.5),
                                resolution: const CoverResolution.extraLarge(),
                                coverID: artist.coverID,
                                borderRadius: 10,
                                isFavorite: isFavorite,
                                getSongs: () async => (await getArtistSongs(
                                        albums: artist.albums,
                                        repository: apiRepository))
                                    .expand((a) => a)
                                    .toList(),
                                getSongsShuffled: () async {
                                  final option = await ChooserDialog.choose(
                                      context, "Shuffle", ["Albums", "Songs"]);
                                  if (option == null) return [];
                                  if (option == 0) {
                                    return ((await getArtistSongs(
                                            albums: artist.albums,
                                            repository: apiRepository))
                                          ..shuffle())
                                        .expand((a) => a)
                                        .toList();
                                  } else {
                                    return (await getArtistSongs(
                                            albums: artist.albums,
                                            repository: apiRepository))
                                        .expand((a) => a)
                                        .toList()
                                      ..shuffle();
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
                      actions: [
                        CollectionAction(
                          title: "Play",
                          icon: Icons.play_arrow,
                          onClick: () async {
                            final songs = (await getArtistSongs(
                                    albums: artist.albums,
                                    repository: apiRepository))
                                .expand((a) => a)
                                .toList();
                            audioHandler.playOnNextMediaChange();
                            audioHandler.mediaQueue.replaceQueue(songs);
                          },
                        ),
                        CollectionAction(
                          title: "Shuffle",
                          icon: Icons.shuffle,
                          onClick: () async {
                            final option = await ChooserDialog.choose(
                                context, "Shuffle", ["Albums", "Songs"]);
                            if (option == null) return;
                            List<Media> songs;
                            if (option == 0) {
                              songs = ((await getArtistSongs(
                                      albums: artist.albums,
                                      repository: apiRepository))
                                    ..shuffle())
                                  .expand((a) => a)
                                  .toList();
                            } else {
                              songs = (await getArtistSongs(
                                      albums: artist.albums,
                                      repository: apiRepository))
                                  .expand((a) => a)
                                  .toList()
                                ..shuffle();
                            }
                            audioHandler.playOnNextMediaChange();
                            audioHandler.mediaQueue.replaceQueue(songs);
                          },
                        ),
                        CollectionAction(
                          title: "Prio. Queue",
                          icon: Icons.playlist_play,
                          onClick: () async {
                            final songs = (await getArtistSongs(
                                    albums: artist.albums,
                                    repository: apiRepository))
                                .expand((a) => a)
                                .toList();
                            audioHandler.mediaQueue
                                .addAllToPriorityQueue(songs);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  'Added "${artist.name}" to priority queue'),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(milliseconds: 1250),
                            ));
                          },
                        ),
                        CollectionAction(
                          title: "Queue",
                          icon: Icons.playlist_add_outlined,
                          onClick: () async {
                            final songs = (await getArtistSongs(
                                    albums: artist.albums,
                                    repository: apiRepository))
                                .expand((a) => a)
                                .toList();
                            audioHandler.mediaQueue.addAll(songs);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Added "${artist.name}" to queue'),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(milliseconds: 1250),
                            ));
                          },
                        ),
                      ],
                      extraInfo: [
                        CollectionExtraInfo(
                            text: artist.genres.isNotEmpty
                                ? artist.genres
                                    .sublist(0, min(3, artist.genres.length))
                                    .join(", ")
                                : "Unknown genre"),
                      ],
                      content: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Column(
                              crossAxisAlignment: constraints.maxWidth > 500
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
                                              coverID: artist.albums[i].coverID,
                                              extraInfo: artist
                                                          .albums[i].year !=
                                                      null
                                                  ? "${artist.albums[i].year}"
                                                  : "Unknown year",
                                            ),
                                          )),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
            };
          },
        ),
      ),
    );
  }

  Future<List<List<Media>>> getArtistSongs({
    required List<ArtistAlbum> albums,
    required APIRepository repository,
  }) async {
    return await Future.wait((albums).map((a) async {
      final album = await repository.getAlbum(a.id);
      return album.song ?? <Media>[];
    }));
  }
}
