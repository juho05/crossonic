import 'dart:math';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/ui/common/cover_art_decorated.dart';
import 'package:crossonic/ui/common/dialogs/chooser.dart';
import 'package:crossonic/ui/main/now_playing/now_playing_menu_options.dart';
import 'package:crossonic/ui/main/now_playing/now_playing_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class NowPlayingExpanded extends StatelessWidget {
  final PanelController _panelController;
  final NowPlayingViewModel _viewModel;

  const NowPlayingExpanded(
      {required PanelController panelController,
      required NowPlayingViewModel viewModel,
      super.key})
      : _panelController = panelController,
        _viewModel = viewModel;

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: constraints.maxHeight * 0.5,
                    width: constraints.maxWidth - 16,
                    child: CoverArtDecorated(
                      coverId: _viewModel.coverId,
                      borderRadius: BorderRadius.circular(10),
                      isFavorite: _viewModel.favorite,
                      placeholderIcon: Icons.album,
                      menuOptions: getNowPlayingMenuOptions(_viewModel),
                    ),
                  ),
                  StreamBuilder(
                    stream: _viewModel.position,
                    initialData: _viewModel.position.value,
                    builder: (context, snapshot) {
                      final pos = snapshot.data ??
                          (position: Duration.zero, bufferedPosition: null);
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: SizedBox(
                          width: min(constraints.maxHeight * 0.50,
                              constraints.maxWidth - 25),
                          child: ProgressBar(
                            progress: pos.position,
                            buffered: pos.bufferedPosition,
                            total: _viewModel.duration ?? pos.position,
                            onDragUpdate: (details) {
                              _panelController.panelPosition = 1;
                            },
                            onSeek: (value) {
                              _viewModel.seek(value);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _viewModel.songTitle,
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
                        if (_viewModel.album != null) {
                          // TODO open album page
                          _panelController.close();
                        }
                      },
                      child: Text(
                        _viewModel.album?.name ?? "Unknown album",
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
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
                            context, _viewModel.artists.toList());
                        if (artistID == null) return;
                        // TODO open artist page
                        _panelController.close();
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          _viewModel.displayArtist,
                          style:
                              Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous, size: 35),
                        onPressed: () {
                          _viewModel.playPrev();
                        },
                      ),
                      IconButton(
                        icon: switch (_viewModel.playbackStatus) {
                          PlaybackStatus.playing =>
                            const Icon(Icons.pause_circle, size: 75),
                          PlaybackStatus.paused =>
                            const Icon(Icons.play_circle, size: 75),
                          _ => const SizedBox(
                              width: 75,
                              height: 75,
                              child: CircularProgressIndicator.adaptive()),
                        },
                        onPressed: () {
                          _viewModel.playPause();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, size: 35),
                        onPressed: () {
                          _viewModel.playNext();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          // TODO open lyrics page
                        },
                        icon: const Icon(Icons.lyrics_outlined),
                      ),
                      IconButton(
                        onPressed: () {
                          // TODO open queue page
                        },
                        icon: const Icon(Icons.queue_music),
                      ),
                      IconButton(
                        onPressed: () {
                          _viewModel.toggleLoop();
                        },
                        icon: _viewModel.loopEnabled
                            ? const Icon(Icons.repeat_on)
                            : const Icon(Icons.repeat),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
