import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/ui/common/cover_art.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:crossonic/ui/main/now_playing/now_playing_menu_options.dart';
import 'package:crossonic/ui/main/now_playing/now_playing_viewmodel.dart';
import 'package:crossonic/ui/main/now_playing/scrolling_song_title.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class NowPlayingCollapsed extends StatelessWidget {
  final PanelController _panelController;
  final NowPlayingViewModel _viewModel;

  const NowPlayingCollapsed({
    required PanelController panelController,
    required NowPlayingViewModel viewModel,
    super.key,
  }) : _panelController = panelController,
       _viewModel = viewModel;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return WithContextMenu(
      options: getNowPlayingMenuOptions(context, _viewModel),
      child: GestureDetector(
        onTap: _panelController.open,
        child: ColoredBox(
          color: colorScheme.brightness == Brightness.dark
              ? colorScheme.surfaceContainerHigh
              : colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7.5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Tooltip(
                  message: _viewModel.album?.name,
                  waitDuration: const Duration(milliseconds: 500),
                  triggerMode: TooltipTriggerMode.manual,
                  child: SizedBox(
                    height: 40,
                    child: CoverArt(
                      placeholderIcon: Icons.album,
                      coverId: _viewModel.coverId,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(width: 7.5),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ScrollingSongTitle(
                        title: _viewModel.songTitle,
                        style: textStyle.bodyMedium!.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Tooltip(
                        message: _viewModel.displayArtist,
                        waitDuration: const Duration(milliseconds: 500),
                        triggerMode: TooltipTriggerMode.manual,
                        child: Text(
                          _viewModel.displayArtist,
                          style: textStyle.bodySmall!.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
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
                      if (!context.mounted) return;
                      toastResult(context, result);
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
                    StreamBuilder<
                      ({Duration position, Duration? bufferedPosition})
                    >(
                      stream: _viewModel.position,
                      initialData: _viewModel.position.value,
                      builder: (context, snapshot) {
                        final pos =
                            snapshot.data ??
                            (position: Duration.zero, bufferedPosition: null);
                        final showPos =
                            _viewModel.duration != null &&
                            (_viewModel.playbackStatus ==
                                    PlaybackStatus.playing ||
                                _viewModel.playbackStatus ==
                                    PlaybackStatus.paused);
                        final duration = _viewModel.duration ?? Duration.zero;
                        return Stack(
                          children: [
                            CircularProgressIndicator(
                              value: showPos ? 1 : 0,
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withAlpha(61),
                            ),
                            if (pos.bufferedPosition != null)
                              CircularProgressIndicator(
                                value: showPos
                                    ? pos.bufferedPosition!.inMilliseconds
                                              .toDouble() /
                                          duration.inMilliseconds.toDouble()
                                    : 0,
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withAlpha(61),
                              ),
                            CircularProgressIndicator(
                              value: showPos
                                  ? pos.position.inMilliseconds.toDouble() /
                                        duration.inMilliseconds.toDouble()
                                  : 0,
                            ),
                          ],
                        );
                      },
                    ),
                    if (_viewModel.playbackStatus != PlaybackStatus.playing &&
                        _viewModel.playbackStatus != PlaybackStatus.paused)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator.adaptive(),
                      ),
                    IconButton(
                      icon: switch (_viewModel.playbackStatus) {
                        PlaybackStatus.stopped || PlaybackStatus.loading =>
                          const SizedBox(width: 24, height: 24),
                        _ => Icon(
                          _viewModel.playbackStatus == PlaybackStatus.playing
                              ? Icons.pause
                              : Icons.play_arrow,
                          size: 24,
                        ),
                      },
                      onPressed:
                          _viewModel.playbackStatus == PlaybackStatus.playing ||
                              _viewModel.playbackStatus == PlaybackStatus.paused
                          ? () {
                              _viewModel.playPause();
                            }
                          : null,
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
      ),
    );
  }
}
