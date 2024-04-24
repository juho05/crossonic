import 'dart:math';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:crossonic/features/home/view/state/now_playing_cubit.dart';
import 'package:crossonic/services/audio_player/audio_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
                  SizedBox(
                    height: 35,
                    width: 35,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      clipBehavior: Clip.antiAlias,
                      child: CachedNetworkImage(
                          fit: BoxFit.cover,
                          imageUrl: state.coverArtURL,
                          useOldImageOnUrlChange: false,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator.adaptive(),
                          fadeInDuration: const Duration(milliseconds: 300),
                          fadeOutDuration: const Duration(milliseconds: 100),
                          errorWidget: (context, url, error) {
                            return const Icon(Icons.album);
                          }),
                    ),
                  ),
                  const SizedBox(width: 7.5),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.songName,
                        style: textStyle.bodyMedium!.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer),
                      ),
                      Text(state.artist,
                          style: textStyle.bodySmall!.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer)),
                    ],
                  ),
                  const Expanded(
                    child: SizedBox(),
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
                      if (state.duration.inMilliseconds > 0)
                        CircularProgressIndicator.adaptive(
                            value: state.playbackState.position.inMilliseconds
                                    .toDouble() /
                                state.duration.inMilliseconds.toDouble()),
                      if (state.playbackState.status ==
                          CrossonicPlaybackStatus.loading)
                        const CircularProgressIndicator.adaptive(),
                      if (state.playbackState.status !=
                              CrossonicPlaybackStatus.idle &&
                          state.playbackState.status !=
                              CrossonicPlaybackStatus.loading)
                        IconButton(
                          icon: Icon(state.playbackState.status ==
                                  CrossonicPlaybackStatus.playing
                              ? Icons.pause
                              : Icons.play_arrow),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: min(constraints.maxHeight * 0.50,
                          constraints.maxWidth - 20),
                      width: min(constraints.maxHeight * 0.50,
                          constraints.maxWidth - 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        clipBehavior: Clip.antiAlias,
                        child: CachedNetworkImage(
                            fit: BoxFit.cover,
                            imageUrl: state.coverArtURL,
                            useOldImageOnUrlChange: false,
                            placeholder: (context, url) => Icon(
                                  Icons.album,
                                  opticalSize: constraints.maxHeight != 0
                                      ? min(constraints.maxHeight * 0.45,
                                          constraints.maxWidth - 35)
                                      : 100,
                                  size: constraints.maxHeight != 0
                                      ? min(constraints.maxHeight * 0.45,
                                          constraints.maxWidth - 35)
                                      : 100,
                                ),
                            fadeInDuration: const Duration(milliseconds: 300),
                            fadeOutDuration: const Duration(milliseconds: 100),
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
                    ),
                    Text(
                      state.album,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 17,
                          ),
                    ),
                    Text(
                      state.artist,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 30),
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
                              icon: state.playbackState.status ==
                                      CrossonicPlaybackStatus.playing
                                  ? const Icon(Icons.pause_circle, size: 75)
                                  : const Icon(Icons.play_circle, size: 75),
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
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
