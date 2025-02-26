import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/ui/common/clickable_list_item_with_context_menu.dart';
import 'package:crossonic/ui/common/cover_art.dart';
import 'package:crossonic/ui/common/song_list_item_viewmodel.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:crossonic/utils/exceptions.dart';
import 'package:crossonic/utils/format.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SongListItem extends StatefulWidget {
  final String id;
  final String title;
  final String? artist;
  final String? album;
  final int? year;
  final int? trackNr;
  final String? coverId;
  final Duration? duration;

  final void Function()? onTap;
  final void Function(bool priority)? onAddToQueue;
  final void Function()? onAddToPlaylist;
  final void Function()? onGoToAlbum;
  final void Function()? onGoToArtist;
  final void Function()? onRemove;

  const SongListItem({
    super.key,
    required this.id,
    required this.title,
    this.artist,
    this.album,
    this.year,
    this.trackNr,
    this.coverId,
    this.duration,
    this.onTap,
    this.onAddToQueue,
    this.onAddToPlaylist,
    this.onGoToAlbum,
    this.onGoToArtist,
    this.onRemove,
  });

  @override
  State<SongListItem> createState() => _SongListItemState();
}

class _SongListItemState extends State<SongListItem> {
  late final SongListItemViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = SongListItemViewModel(
      favoritesRepository: context.read(),
      audioHandler: context.read(),
      songId: widget.id,
    );
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: viewModel,
        builder: (context, snapshot) {
          return ClickableListItemWithContextMenu(
            title: widget.title,
            titleBold: viewModel.playbackStatus != null,
            extraInfo: [
              if (widget.artist != null) widget.artist!,
              if (widget.album != null) widget.album!,
              if (widget.year != null) widget.year!.toString(),
            ],
            leading: SongLeadingWidget(
              viewModel: viewModel,
              coverId: widget.coverId,
              trackNr: widget.trackNr,
            ),
            trailingInfo: widget.duration != null
                ? formatDuration(widget.duration!)
                : null,
            onTap: widget.onTap,
            isFavorite: viewModel.favorite,
            options: [
              if (widget.onAddToQueue != null)
                ContextMenuOption(
                  icon: Icons.playlist_add,
                  title: "Add to queue",
                  onSelected: () => widget.onAddToQueue!(false),
                ),
              if (widget.onAddToQueue != null)
                ContextMenuOption(
                  icon: Icons.playlist_play,
                  title: "Add to priority queue",
                  onSelected: () => widget.onAddToQueue!(true),
                ),
              ContextMenuOption(
                icon: viewModel.favorite ? Icons.heart_broken : Icons.favorite,
                title: viewModel.favorite
                    ? "Remove from favorites"
                    : "Add to favorites",
                onSelected: () async {
                  final result = await viewModel.toggleFavorite();
                  if (result is Error && context.mounted) {
                    if (result.error is ConnectionException) {
                      Toast.show(context, "Failed to contact server");
                    } else {
                      Toast.show(context, "An unexpected error occured");
                    }
                  }
                },
              ),
              if (widget.onAddToPlaylist != null)
                ContextMenuOption(
                  icon: Icons.playlist_add,
                  title: "Add to playlist",
                  onSelected: widget.onAddToPlaylist,
                ),
              if (widget.onGoToAlbum != null)
                ContextMenuOption(
                  icon: Icons.album,
                  title: "Go to album",
                  onSelected: widget.onGoToAlbum,
                ),
              if (widget.onGoToArtist != null)
                ContextMenuOption(
                  icon: Icons.person,
                  title: "Go to artist",
                  onSelected: widget.onGoToArtist,
                ),
              if (widget.onRemove != null)
                ContextMenuOption(
                  icon: Icons.playlist_remove,
                  title: "Remove",
                  onSelected: widget.onRemove,
                ),
            ],
          );
        });
  }
}

class SongLeadingWidget extends StatelessWidget {
  final int? trackNr;
  final String? coverId;

  final SongListItemViewModel viewModel;

  const SongLeadingWidget({
    super.key,
    this.trackNr,
    this.coverId,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (trackNr != null) {
      return SizedBox(
        child: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: viewModel.playbackStatus == null
                  ? Text(
                      trackNr!.toString().padLeft(2, "0"),
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium!
                          .copyWith(fontWeight: FontWeight.w500),
                    )
                  : IconButton(
                      onPressed: () {
                        viewModel.playPause();
                      },
                      icon: Icon(
                        viewModel.playbackStatus == PlaybackStatus.playing
                            ? Icons.pause
                            : (viewModel.playbackStatus ==
                                    PlaybackStatus.loading
                                ? Icons.hourglass_empty
                                : Icons.play_arrow),
                      ),
                    ),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CoverArt(
              placeholderIcon: Icons.album,
              coverId: coverId,
              borderRadius: BorderRadius.circular(5),
            ),
            if (viewModel.playbackStatus != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: ColoredBox(color: Color.fromARGB(90, 0, 0, 0)),
              ),
            if (viewModel.playbackStatus != null)
              IconButton(
                onPressed: () {
                  viewModel.playPause();
                },
                icon: Icon(
                  viewModel.playbackStatus == PlaybackStatus.playing
                      ? Icons.pause
                      : (viewModel.playbackStatus == PlaybackStatus.loading
                          ? Icons.hourglass_empty
                          : Icons.play_arrow),
                ),
              )
          ],
        ),
      ),
    );
  }
}
