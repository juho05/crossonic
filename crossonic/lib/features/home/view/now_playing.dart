import 'dart:math';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:crossonic/features/home/view/state/now_playing_cubit.dart';
import 'package:crossonic/services/audio_player/audio_handler.dart';
import 'package:crossonic/widgets/cover_art.dart';
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
                          state.artist,
                          style: textStyle.bodySmall!.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: () {
                      context.read<CrossonicAudioHandler>().skipToPrevious();
                    },
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
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: () {
                      context.read<CrossonicAudioHandler>().skipToNext();
                    },
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

class NowPlaying extends StatelessWidget {
  final PanelController _panelController;

  const NowPlaying({required PanelController panelController, super.key})
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
                      CoverArt(
                        size: min(constraints.maxHeight * 0.50,
                            constraints.maxWidth - 12),
                        coverID: state.coverArtID,
                        resolution: const CoverResolution.extraLarge(),
                        borderRadius: BorderRadius.circular(10),
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
                          onTap: () {
                            if (state.artistID != "") {
                              context.push("/home/artist/${state.artistID}");
                              _panelController.close();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              state.artist,
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
                      IconButton(
                        onPressed: () {
                          context.push("/queue");
                        },
                        icon: const Icon(Icons.queue_music),
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
