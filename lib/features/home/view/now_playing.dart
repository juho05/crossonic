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
                  const SizedBox(
                    height: 35,
                    width: 35,
                    child: ColoredBox(color: Colors.red),
                  ),
                  const SizedBox(width: 7.5),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(state.songName, style: textStyle.bodyMedium),
                      Text(
                        state.artist,
                        style: textStyle.bodySmall,
                      ),
                    ],
                  ),
                  const Expanded(
                    child: SizedBox(),
                  ),
                  IconButton(
                    icon: Icon(state.playing ? Icons.pause : Icons.play_arrow),
                    onPressed: () {
                      context.read<CrossonicAudioHandler>().togglePlayPause();
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
