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
                      child: CachedNetworkImage(
                          width: 35,
                          height: 35,
                          imageUrl: "${state.coverArtURL}&size=64",
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
    return const Placeholder();
  }
}
