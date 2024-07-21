import 'dart:math';

import 'package:crossonic/components/collection_page.dart';
import 'package:crossonic/components/state/layout.dart';
import 'package:crossonic/features/album/state/album_cubit.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:crossonic/services/audio_handler/audio_handler.dart';
import 'package:crossonic/components/app_bar.dart';
import 'package:crossonic/components/chooser.dart';
import 'package:crossonic/components/cover_art.dart';
import 'package:crossonic/components/large_cover.dart';
import 'package:crossonic/components/song.dart';
import 'package:crossonic/components/state/favorites_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AlbumPage extends StatelessWidget {
  const AlbumPage({super.key, required this.albumID});

  final String albumID;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AlbumCubit(context.read<APIRepository>()),
      child: Scaffold(
        appBar: createAppBar(context, "Album"),
        body: BlocBuilder<AlbumCubit, AlbumState>(
          builder: (context, album) {
            if (album.id != albumID && album.status != FetchStatus.failure) {
              context.read<AlbumCubit>().updateID(albumID);
              return const Center(child: CircularProgressIndicator.adaptive());
            }
            final audioHandler = context.read<CrossonicAudioHandler>();
            return switch (album.status) {
              FetchStatus.initial ||
              FetchStatus.loading =>
                const Center(child: CircularProgressIndicator.adaptive()),
              FetchStatus.failure => const Center(child: Icon(Icons.wifi_off)),
              FetchStatus.success => LayoutBuilder(
                  builder: (context, constraints) {
                    return CollectionPage(
                      name: album.name,
                      cover: BlocBuilder<FavoritesCubit, FavoritesState>(
                        buildWhen: (previous, current) =>
                            current.changedId == album.id,
                        builder: (context, state) {
                          final isFavorite = state.favorites.contains(album.id);
                          final layout = context.watch<Layout>();
                          return LayoutBuilder(
                            builder: (context, constraints2) =>
                                CoverArtWithMenu(
                              id: album.id,
                              name: album.name,
                              artists: album.artists.artists.toList(),
                              enablePlay: true,
                              enableShuffle: true,
                              enableQueue: true,
                              isFavorite: isFavorite,
                              size: layout.size == LayoutSize.mobile
                                  ? min(constraints.maxHeight * 0.60,
                                      constraints.maxWidth - 24)
                                  : min(constraints2.maxWidth,
                                      MediaQuery.sizeOf(context).height * 0.5),
                              resolution: const CoverResolution.extraLarge(),
                              coverID: album.coverID,
                              borderRadius: 10,
                              getSongs: () async => album.subsonicSongs,
                            ),
                          );
                        },
                      ),
                      extraInfo: [
                        CollectionExtraInfo(
                          text: album.artists.displayName +
                              (album.year > 0 ? ' • ${album.year}' : ''),
                          onClick: () async {
                            final artistID = await ChooserDialog.chooseArtist(
                                context, album.artists.artists.toList());
                            if (artistID == null) return;
                            // ignore: use_build_context_synchronously
                            context.push("/home/artist/$artistID");
                          },
                        ),
                      ],
                      actions: [
                        CollectionAction(
                          title: "Play",
                          icon: Icons.play_arrow,
                          onClick: () {
                            audioHandler.playOnNextMediaChange();
                            audioHandler.mediaQueue
                                .replaceQueue(album.subsonicSongs);
                          },
                        ),
                        CollectionAction(
                          title: "Prio. Queue",
                          icon: Icons.playlist_play,
                          onClick: () {
                            audioHandler.mediaQueue
                                .addAllToPriorityQueue(album.subsonicSongs);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  'Added "${album.name}" to priority queue'),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(milliseconds: 1250),
                            ));
                          },
                        ),
                        CollectionAction(
                          title: "Queue",
                          icon: Icons.playlist_add_outlined,
                          onClick: () {
                            audioHandler.mediaQueue.addAll(album.subsonicSongs);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Added "${album.name}" to queue'),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(milliseconds: 1250),
                            ));
                          },
                        ),
                      ],
                      contentTitle: "Tracks (${album.songs.length})",
                      content: Column(
                        children: List<Widget>.generate(
                          album.songs.length,
                          (i) => Song(
                            key: ValueKey(i),
                            song: album.subsonicSongs[i],
                            leadingItem: SongLeadingItem.track,
                            showGotoAlbum: false,
                            onTap: () {
                              audioHandler.playOnNextMediaChange();
                              audioHandler.mediaQueue
                                  .replaceQueue(album.subsonicSongs, i);
                            },
                          ),
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
}
