import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/ui/common/cover_art.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/ui/main/now_playing/now_playing_viewmodel.dart';
import 'package:crossonic/utils/exceptions.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class NowPlayingCollapsed extends StatelessWidget {
  final PanelController _panelController;
  final NowPlayingViewModel _viewModel;

  const NowPlayingCollapsed(
      {required PanelController panelController,
      required NowPlayingViewModel viewModel,
      super.key})
      : _panelController = panelController,
        _viewModel = viewModel;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: _panelController.open,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7.5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 40,
                child: CoverArt(
                  placeholderIcon: Icons.album,
                  coverId: _viewModel.coverId,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 7.5),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _viewModel.songTitle,
                      style: textStyle.bodyMedium!.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _viewModel.displayArtist,
                      style: textStyle.bodySmall!.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 32,
                height: 40,
                child: IconButton(
                  icon: _viewModel.favorite
                      ? const Icon(Icons.favorite, size: 20)
                      : const Icon(Icons.favorite_border, size: 20),
                  padding: const EdgeInsets.all(0),
                  onPressed: () async {
                    final result = await _viewModel.toggleFavorite();
                    if (result is Err && context.mounted) {
                      if (result.error is ConnectionException) {
                        Toast.show(context, "Failed to contact server");
                      } else {
                        Toast.show(context, "An unexpected error occured");
                      }
                    }
                  },
                ),
              ),
              SizedBox(
                width: 32,
                height: 40,
                child: IconButton(
                  icon: const Icon(Icons.skip_previous),
                  padding: const EdgeInsets.all(0),
                  onPressed: () {
                    _viewModel.playPrev();
                  },
                ),
              ),
              Stack(
                alignment: Alignment.center,
                fit: StackFit.passthrough,
                children: [
                  if (_viewModel.duration != null)
                    StreamBuilder<
                            ({Duration position, Duration? bufferedPosition})>(
                        stream: _viewModel.position,
                        initialData: _viewModel.position.value,
                        builder: (context, snapshot) {
                          final pos = snapshot.data ??
                              (position: Duration.zero, bufferedPosition: null);
                          return CircularProgressIndicator(
                            value: pos.position.inMilliseconds.toDouble() /
                                _viewModel.duration!.inMilliseconds.toDouble(),
                          );
                        }),
                  if (_viewModel.playbackStatus != PlaybackStatus.playing &&
                      _viewModel.playbackStatus != PlaybackStatus.paused)
                    const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator.adaptive()),
                  IconButton(
                    icon: switch (_viewModel.playbackStatus) {
                      PlaybackStatus.stopped ||
                      PlaybackStatus.loading =>
                        const SizedBox(width: 24, height: 24),
                      _ => Icon(
                          _viewModel.playbackStatus == PlaybackStatus.playing
                              ? Icons.pause
                              : Icons.play_arrow,
                          size: 24,
                        ),
                    },
                    onPressed: () {
                      _viewModel.playPause();
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
                    _viewModel.playNext();
                  },
                ),
              ),
              const SizedBox(width: 2),
            ],
          ),
        ),
      ),
    );
  }
}
