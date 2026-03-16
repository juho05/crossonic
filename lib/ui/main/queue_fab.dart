import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/auto_hide_fab.dart';
import 'package:crossonic/ui/main/now_playing/now_playing_viewmodel.dart';
import 'package:flutter/material.dart';

class QueueFab extends StatelessWidget {
  final NowPlayingViewModel _nowPlayingViewModel;
  final bool _hide;

  const QueueFab({
    super.key,
    required NowPlayingViewModel nowPlayingViewModel,
    bool hide = false,
  }) : _nowPlayingViewModel = nowPlayingViewModel,
       _hide = hide;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _nowPlayingViewModel,
      builder: (context, child) {
        if (_hide ||
            _nowPlayingViewModel.playbackStatus != PlaybackStatus.stopped ||
            !_nowPlayingViewModel.hasNamedQueues) {
          return const SizedBox.shrink();
        }
        return AutoHideFAB(
          onPressed: () {
            context.router.push(const SelectQueueRoute());
          },
          tooltip: "Select queue",
          child: const Icon(Icons.queue_music),
        );
      },
    );
  }
}
