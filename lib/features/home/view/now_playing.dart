import 'dart:math';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:crossonic/features/home/view/state/now_playing_cubit.dart';
import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:crossonic/services/audio_handler/audio_handler.dart';
import 'package:crossonic/components/chooser.dart';
import 'package:crossonic/components/cover_art.dart';
import 'package:crossonic/components/large_cover.dart';
import 'package:crossonic/components/state/favorites_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class NowPlayingCollapsed extends StatelessWidget {
  final PanelController _panelController;

  const NowPlayingCollapsed(
      {required PanelController panelController, super.key})
      : _panelController = panelController;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _panelController.open,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: BlocBuilder<NowPlayingCubit, NowPlayingState>(
          builder: (context, state) {
            final textStyle = Theme.of(context).textTheme;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7.5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CoverArt(
                    size: 40,
                    coverID: state.coverArtID,
                    borderRadius: BorderRadius.circular(5),
                    resolution: const CoverResolution.tiny(),
                  ),
                  const SizedBox(width: 7.5),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.songName,
                          style: textStyle.bodyMedium!.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          state.artists.displayName,
                          style: textStyle.bodySmall!.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  BlocBuilder<FavoritesCubit, FavoritesState>(
                    buildWhen: (previous, current) =>
                        current.changedId == state.songID,
                    builder: (context, favState) {
                      final isFavorite =
                          favState.favorites.contains(state.songID);
                      return SizedBox(
                        width: 32,
                        height: 40,
                        child: IconButton(
                          icon: isFavorite
                              ? const Icon(Icons.favorite, size: 20)
                              : const Icon(Icons.favorite_border, size: 20),
                          padding: const EdgeInsets.all(0),
                          onPressed: () {
                            context
                                .read<FavoritesCubit>()
                                .toggleFavorite(state.songID);
                          },
                        ),
                      );
                    },
                  ),
                  SizedBox(
                    width: 32,
                    height: 40,
                    child: IconButton(
                      icon: const Icon(Icons.skip_previous),
                      padding: const EdgeInsets.all(0),
                      onPressed: () {
                        context.read<CrossonicAudioHandler>().skipToPrevious();
                      },
                    ),
                  ),
                  Stack(
                    alignment: Alignment.center,
                    fit: StackFit.passthrough,
                    children: [
                      if (state.duration.inMilliseconds > 0 &&
                          state.playbackState.status !=
                              CrossonicPlaybackStatus.loading)
                        CircularProgressIndicator(
                            value: state.playbackState.position.inMilliseconds
                                    .toDouble() /
                                state.duration.inMilliseconds.toDouble()),
                      if (state.playbackState.status !=
                              CrossonicPlaybackStatus.playing &&
                          state.playbackState.status !=
                              CrossonicPlaybackStatus.paused)
                        const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator.adaptive()),
                      IconButton(
                        icon: switch (state.playbackState.status) {
                          CrossonicPlaybackStatus.stopped ||
                          CrossonicPlaybackStatus.loading =>
                            const SizedBox(width: 24, height: 24),
                          _ => Icon(
                              state.playbackState.status ==
                                      CrossonicPlaybackStatus.playing
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 24,
                            )
                        },
                        onPressed: () {
                          context.read<CrossonicAudioHandler>().playPause();
                        },
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 32,
                    height: 40,
                    child: IconButton(
                      icon: const Icon(Icons.skip_next),
                      padding: const EdgeInsets.all(0),
                      onPressed: () {
                        context.read<CrossonicAudioHandler>().skipToNext();
                      },
                    ),
                  ),
                  const SizedBox(width: 2),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class NowPlayingExpanded extends StatelessWidget {
  final PanelController _panelController;

  const NowPlayingExpanded(
      {required PanelController panelController, super.key})
      : _panelController = panelController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.expand_more),
          onPressed: () {
            _panelController.close();
          },
        ),
        titleSpacing: 0,
        title: const Text('Now playing'),
      ),
      body: BlocBuilder<NowPlayingCubit, NowPlayingState>(
        buildWhen: (previous, current) => previous.songID != current.songID,
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      BlocBuilder<FavoritesCubit, FavoritesState>(
                        buildWhen: (previous, current) =>
                            current.changedId == state.songID,
                        builder: (context, favState) {
                          final isFavorite =
                              favState.favorites.contains(state.songID);
                          return CoverArtWithMenu(
                            id: state.songID,
                            name: state.songName,
                            albumID: state.albumID,
                            artists: state.artists.artists.toList(),
                            enablePlay: false,
                            enableShuffle: false,
                            enableQueue: true,
                            getSongs: () async =>
                                state.media != null ? [state.media!] : [],
                            size: min(constraints.maxHeight * 0.50,
                                constraints.maxWidth - 12),
                            coverID: state.coverArtID,
                            resolution: const CoverResolution.extraLarge(),
                            borderRadius: 10,
                            isFavorite: isFavorite,
                            onGoTo: () => _panelController.close(),
                          );
                        },
                      ),
                      BlocBuilder<NowPlayingCubit, NowPlayingState>(
                        buildWhen: (previous, current) =>
                            previous.duration != current.duration ||
                            previous.playbackState.position !=
                                current.playbackState.position,
                        builder: (context, state) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: SizedBox(
                              width: min(constraints.maxHeight * 0.50,
                                  constraints.maxWidth - 25),
                              child: ProgressBar(
                                progress: state.playbackState.position,
                                buffered:
                                    state.playbackState.bufferedPosition !=
                                            Duration.zero
                                        ? state.playbackState.bufferedPosition
                                        : null,
                                total: state.duration,
                                onDragUpdate: (details) {
                                  _panelController.panelPosition = 1;
                                },
                                onSeek: (value) {
                                  context
                                      .read<CrossonicAudioHandler>()
                                      .seek(value);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        state.songName,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            if (state.albumID != "") {
                              context.push("/home/album/${state.albumID}");
                              _panelController.close();
                            }
                          },
                          child: Text(
                            state.album,
                            style:
                                Theme.of(context).textTheme.bodyLarge!.copyWith(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 17,
                                    ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () async {
                            final artistID = await ChooserDialog.chooseArtist(
                                context, state.artists.artists.toList());
                            if (artistID == null) return;
                            // ignore: use_build_context_synchronously
                            context.push("/home/artist/$artistID");
                            _panelController.close();
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              state.artists.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      BlocBuilder<NowPlayingCubit, NowPlayingState>(
                        buildWhen: (previous, current) =>
                            previous.playbackState != current.playbackState,
                        builder: (context, state) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.skip_previous, size: 35),
                                onPressed: () {
                                  context
                                      .read<CrossonicAudioHandler>()
                                      .skipToPrevious();
                                },
                              ),
                              IconButton(
                                icon: switch (state.playbackState.status) {
                                  CrossonicPlaybackStatus.playing =>
                                    const Icon(Icons.pause_circle, size: 75),
                                  CrossonicPlaybackStatus.paused =>
                                    const Icon(Icons.play_circle, size: 75),
                                  _ => const SizedBox(
                                      width: 75,
                                      height: 75,
                                      child:
                                          CircularProgressIndicator.adaptive()),
                                },
                                onPressed: () {
                                  context
                                      .read<CrossonicAudioHandler>()
                                      .playPause();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.skip_next, size: 35),
                                onPressed: () {
                                  context
                                      .read<CrossonicAudioHandler>()
                                      .skipToNext();
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {
                              context.push("/lyrics");
                            },
                            icon: const Icon(Icons.lyrics_outlined),
                          ),
                          IconButton(
                            onPressed: () {
                              context.push("/queue");
                            },
                            icon: const Icon(Icons.queue_music),
                          ),
                          BlocBuilder<NowPlayingCubit, NowPlayingState>(
                            buildWhen: (previous, current) =>
                                previous.loop != current.loop,
                            builder: (context, state) {
                              return IconButton(
                                onPressed: () {
                                  context.read<NowPlayingCubit>().toggleLoop();
                                },
                                icon: state.loop
                                    ? const Icon(Icons.repeat_on)
                                    : const Icon(Icons.repeat),
                              );
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

enum SongPopupMenuValue {
  addToPriorityQueue,
  addToQueue,
  toggleFavorite,
  addToPlaylist,
  gotoAlbum,
  gotoArtist
}

class NowPlayingDesktop extends StatelessWidget {
  const NowPlayingDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: BlocBuilder<NowPlayingCubit, NowPlayingState>(
          builder: (context, state) {
            final textStyle = Theme.of(context).textTheme;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              if (state.albumID.isNotEmpty) {
                                context.push("/home/album/${state.albumID}");
                              }
                            },
                            child: CoverArt(
                              size: 60,
                              coverID: state.coverArtID,
                              borderRadius: BorderRadius.circular(5),
                              resolution: const CoverResolution.medium(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.songName,
                                style: textStyle.bodyMedium!.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () async {
                                    final artistID =
                                        await ChooserDialog.chooseArtist(
                                            context,
                                            state.artists.artists.toList());
                                    if (artistID == null) return;
                                    // ignore: use_build_context_synchronously
                                    context.push("/home/artist/$artistID");
                                  },
                                  child: Text(
                                    state.artists.displayName,
                                    style: textStyle.bodySmall!.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            BlocBuilder<FavoritesCubit, FavoritesState>(
                              buildWhen: (previous, current) =>
                                  current.changedId == state.songID,
                              builder: (context, favState) {
                                final isFavorite =
                                    favState.favorites.contains(state.songID);
                                return IconButton(
                                  icon: isFavorite
                                      ? const Icon(Icons.favorite)
                                      : const Icon(Icons.favorite_border),
                                  padding: const EdgeInsets.all(0),
                                  onPressed: () {
                                    context
                                        .read<FavoritesCubit>()
                                        .toggleFavorite(state.songID);
                                  },
                                );
                              },
                            ),
                            const SizedBox(width: 7),
                            IconButton(
                              icon: const Icon(Icons.skip_previous, size: 32),
                              padding: const EdgeInsets.all(0),
                              onPressed: () {
                                context
                                    .read<CrossonicAudioHandler>()
                                    .skipToPrevious();
                              },
                            ),
                            const SizedBox(width: 5),
                            if (state.playbackState.status ==
                                    CrossonicPlaybackStatus.loading ||
                                state.playbackState.status ==
                                    CrossonicPlaybackStatus.stopped)
                              const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Padding(
                                    padding: EdgeInsets.all(5.0),
                                    child: CircularProgressIndicator.adaptive(),
                                  )),
                            if (state.playbackState.status !=
                                    CrossonicPlaybackStatus.loading &&
                                state.playbackState.status !=
                                    CrossonicPlaybackStatus.stopped)
                              IconButton(
                                icon: Icon(
                                  state.playbackState.status ==
                                          CrossonicPlaybackStatus.playing
                                      ? Icons.pause_circle
                                      : Icons.play_circle,
                                  size: 40,
                                ),
                                padding: const EdgeInsets.all(0),
                                onPressed: () {
                                  context
                                      .read<CrossonicAudioHandler>()
                                      .playPause();
                                },
                              ),
                            const SizedBox(width: 5),
                            IconButton(
                              icon: const Icon(Icons.skip_next, size: 32),
                              padding: const EdgeInsets.all(0),
                              onPressed: () {
                                context
                                    .read<CrossonicAudioHandler>()
                                    .skipToNext();
                              },
                            ),
                            const SizedBox(width: 7),
                            BlocBuilder<NowPlayingCubit, NowPlayingState>(
                              buildWhen: (previous, current) =>
                                  previous.loop != current.loop,
                              builder: (context, state) {
                                return IconButton(
                                  onPressed: () {
                                    context
                                        .read<NowPlayingCubit>()
                                        .toggleLoop();
                                  },
                                  icon: state.loop
                                      ? const Icon(Icons.repeat_on)
                                      : const Icon(Icons.repeat),
                                );
                              },
                            ),
                          ],
                        ),
                        BlocBuilder<NowPlayingCubit, NowPlayingState>(
                          buildWhen: (previous, current) =>
                              previous.duration != current.duration ||
                              previous.playbackState.position !=
                                  current.playbackState.position,
                          builder: (context, state) {
                            return ProgressBar(
                              timeLabelLocation: TimeLabelLocation.sides,
                              progress: state.playbackState.position,
                              buffered: state.playbackState.bufferedPosition !=
                                      Duration.zero
                                  ? state.playbackState.bufferedPosition
                                  : null,
                              total: state.duration,
                              onSeek: (value) {
                                context
                                    .read<CrossonicAudioHandler>()
                                    .seek(value);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 3,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            context.push("/lyrics");
                          },
                          icon: const Icon(Icons.lyrics_outlined),
                        ),
                        IconButton(
                          onPressed: () {
                            context.push("/queue");
                          },
                          icon: const Icon(Icons.queue_music),
                        ),
                        IconButton(
                          onPressed: () async {
                            await ChooserDialog.addToPlaylist(
                                context, state.songName, [state.media!]);
                          },
                          icon: const Icon(Icons.playlist_add),
                        ),
                        BlocBuilder<FavoritesCubit, FavoritesState>(
                          buildWhen: (previous, current) =>
                              current.changedId == state.songID,
                          builder: (context, fState) {
                            final isFavorite =
                                fState.favorites.contains(state.songID);
                            return PopupMenuButton(
                              onSelected: (value) async {
                                final audioHandler =
                                    context.read<CrossonicAudioHandler>();
                                switch (value) {
                                  case SongPopupMenuValue.addToPriorityQueue:
                                    audioHandler.mediaQueue
                                        .addToPriorityQueue(state.media!);
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text(
                                          'Added "${state.songName}" to priority queue'),
                                      behavior: SnackBarBehavior.floating,
                                      duration:
                                          const Duration(milliseconds: 1250),
                                    ));
                                  case SongPopupMenuValue.addToQueue:
                                    audioHandler.mediaQueue.add(state.media!);
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text(
                                          'Added "${state.songName}" to queue'),
                                      behavior: SnackBarBehavior.floating,
                                      duration:
                                          const Duration(milliseconds: 1250),
                                    ));
                                  case SongPopupMenuValue.toggleFavorite:
                                    context
                                        .read<FavoritesCubit>()
                                        .toggleFavorite(state.songID);
                                  case SongPopupMenuValue.addToPlaylist:
                                    await ChooserDialog.addToPlaylist(context,
                                        state.songName, [state.media!]);
                                  case SongPopupMenuValue.gotoAlbum:
                                    context
                                        .push("/home/album/${state.albumID}");
                                  case SongPopupMenuValue.gotoArtist:
                                    final artistID =
                                        await ChooserDialog.chooseArtist(
                                            context,
                                            APIRepository.getArtistsOfSong(
                                                    state.media!)
                                                .artists
                                                .toList());
                                    if (artistID == null) return;
                                    // ignore: use_build_context_synchronously
                                    context.push("/home/artist/$artistID");
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: SongPopupMenuValue.addToPriorityQueue,
                                  child: ListTile(
                                    leading: Icon(Icons.playlist_play),
                                    title: Text('Add to priority queue'),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: SongPopupMenuValue.addToQueue,
                                  child: ListTile(
                                    leading: Icon(Icons.playlist_add),
                                    title: Text('Add to queue'),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: SongPopupMenuValue.toggleFavorite,
                                  child: ListTile(
                                    leading: Icon(isFavorite
                                        ? Icons.heart_broken
                                        : Icons.favorite),
                                    title: Text(isFavorite
                                        ? 'Remove from favorites'
                                        : 'Add to favorites'),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: SongPopupMenuValue.addToPlaylist,
                                  child: ListTile(
                                    leading: Icon(Icons.playlist_add),
                                    title: Text("Add to playlist"),
                                  ),
                                ),
                                if (state.albumID.isNotEmpty)
                                  const PopupMenuItem(
                                    value: SongPopupMenuValue.gotoAlbum,
                                    child: ListTile(
                                      leading: Icon(Icons.album),
                                      title: Text('Go to album'),
                                    ),
                                  ),
                                if (state.artists.artists.isNotEmpty)
                                  const PopupMenuItem(
                                    value: SongPopupMenuValue.gotoArtist,
                                    child: ListTile(
                                      leading: Icon(Icons.person),
                                      title: Text('Go to artist'),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(width: 5),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
