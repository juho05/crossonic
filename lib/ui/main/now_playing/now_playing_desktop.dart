import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/context_menu_button.dart';
import 'package:crossonic/ui/common/cover_art.dart';
import 'package:crossonic/ui/common/dialogs/chooser.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/ui/main/now_playing/now_playing_menu_options.dart';
import 'package:crossonic/ui/main/now_playing/now_playing_viewmodel.dart';
import 'package:crossonic/utils/exceptions.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class NowPlayingDesktop extends StatelessWidget {
  final NowPlayingViewModel _viewModel;

  const NowPlayingDesktop({required NowPlayingViewModel viewModel, super.key})
      : _viewModel = viewModel;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme;
    return SizedBox(
      height: 80,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
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
                    SizedBox(
                      height: 60,
                      width: 60,
                      child: Stack(
                        children: [
                          CoverArt(
                            coverId: _viewModel.coverId,
                            placeholderIcon: Icons.album,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          if (_viewModel.album != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: Material(
                                type: MaterialType.transparency,
                                child: InkWell(
                                  onTap: () {
                                    context.router.push(AlbumRoute(
                                        albumId: _viewModel.album!.id));
                                  },
                                ),
                              ),
                            )
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _viewModel.songTitle,
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
                                final router = context.router;
                                final artistId =
                                    await ChooserDialog.chooseArtist(
                                        context, _viewModel.artists.toList());
                                if (artistId == null) return;
                                router.push(ArtistRoute(artistId: artistId));
                              },
                              child: Text(
                                _viewModel.displayArtist,
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
                        IconButton(
                          icon: _viewModel.favorite
                              ? const Icon(Icons.favorite)
                              : const Icon(Icons.favorite_border),
                          padding: const EdgeInsets.all(0),
                          onPressed: () async {
                            final result = await _viewModel.toggleFavorite();
                            if (result is Err && context.mounted) {
                              if (result.error is ConnectionException) {
                                Toast.show(context, "Failed to contact server");
                              } else {
                                Toast.show(
                                    context, "An unexpected error occured");
                              }
                            }
                          },
                        ),
                        const SizedBox(width: 7),
                        IconButton(
                          icon: const Icon(Icons.skip_previous, size: 32),
                          padding: const EdgeInsets.all(0),
                          onPressed: () {
                            _viewModel.playPrev();
                          },
                        ),
                        const SizedBox(width: 5),
                        if (_viewModel.playbackStatus ==
                                PlaybackStatus.loading ||
                            _viewModel.playbackStatus == PlaybackStatus.stopped)
                          const SizedBox(
                              width: 40,
                              height: 40,
                              child: Padding(
                                padding: EdgeInsets.all(5.0),
                                child: CircularProgressIndicator.adaptive(),
                              )),
                        if (_viewModel.playbackStatus !=
                                PlaybackStatus.loading &&
                            _viewModel.playbackStatus != PlaybackStatus.stopped)
                          IconButton(
                            icon: Icon(
                              _viewModel.playbackStatus ==
                                      PlaybackStatus.playing
                                  ? Icons.pause_circle
                                  : Icons.play_circle,
                              size: 40,
                            ),
                            padding: const EdgeInsets.all(0),
                            onPressed: () {
                              _viewModel.playPause();
                            },
                          ),
                        const SizedBox(width: 5),
                        IconButton(
                          icon: const Icon(Icons.skip_next, size: 32),
                          padding: const EdgeInsets.all(0),
                          onPressed: () {
                            _viewModel.playNext();
                          },
                        ),
                        const SizedBox(width: 7),
                        IconButton(
                          onPressed: () {
                            _viewModel.toggleLoop();
                          },
                          icon: _viewModel.loopEnabled
                              ? const Icon(Icons.repeat_on)
                              : const Icon(Icons.repeat),
                        ),
                      ],
                    ),
                    StreamBuilder(
                      stream: _viewModel.position,
                      initialData: _viewModel.position.value,
                      builder: (context, snapshot) {
                        final pos = snapshot.data ??
                            (position: Duration.zero, bufferedPosition: null);
                        return ProgressBar(
                          timeLabelLocation: TimeLabelLocation.sides,
                          progress: pos.position,
                          buffered: pos.bufferedPosition,
                          total: _viewModel.duration ?? pos.position,
                          onSeek: (value) {
                            _viewModel.seek(value);
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
                        // TODO open lyrics page
                      },
                      icon: const Icon(Icons.lyrics_outlined),
                    ),
                    IconButton(
                      onPressed: () {
                        context.router.push(QueueRoute());
                      },
                      icon: const Icon(Icons.queue_music),
                    ),
                    ContextMenuButton(
                      options: getNowPlayingMenuOptions(context, _viewModel),
                    ),
                    const SizedBox(width: 5),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
