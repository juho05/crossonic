import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
import 'package:crossonic/ui/common/clickable_list_item_with_context_menu.dart';
import 'package:crossonic/ui/common/cover_art.dart';
import 'package:crossonic/ui/common/dialogs/media_info.dart';
import 'package:crossonic/ui/common/song_list_item_viewmodel.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:crossonic/utils/format.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SongListItem extends StatefulWidget {
  final String id;
  final String title;
  final String? artist;
  final String? album;
  final int? year;
  final int? trackNr;
  final int? trackDigits;
  final String? coverId;
  final Duration? duration;
  final int? reorderIndex;
  final bool disablePlaybackStatus;
  final bool removeButton;
  final DownloadStatus downloadStatus;

  final void Function(bool ctrlPressed)? onTap;
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
    this.trackDigits,
    this.coverId,
    this.duration,
    this.onTap,
    this.onAddToQueue,
    this.onAddToPlaylist,
    this.onGoToAlbum,
    this.onGoToArtist,
    this.onRemove,
    this.reorderIndex,
    this.disablePlaybackStatus = false,
    this.removeButton = false,
    this.downloadStatus = DownloadStatus.none,
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
      disablePlaybackStatus: widget.disablePlaybackStatus,
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
              trackDigits: widget.trackDigits,
              reorderIndex: widget.reorderIndex,
            ),
            trailingInfo: widget.duration != null
                ? formatDuration(widget.duration!)
                : null,
            onTap: widget.onTap != null
                ? () =>
                    widget.onTap!(HardwareKeyboard.instance.isControlPressed)
                : null,
            isFavorite: viewModel.favorite,
            downloadStatus: widget.downloadStatus,
            options: [
              if (widget.onAddToQueue != null)
                ContextMenuOption(
                  icon: Icons.playlist_play,
                  title: "Add to priority queue",
                  onSelected: () => widget.onAddToQueue!(true),
                ),
              if (widget.onAddToQueue != null)
                ContextMenuOption(
                  icon: Icons.playlist_add,
                  title: "Add to queue",
                  onSelected: () => widget.onAddToQueue!(false),
                ),
              ContextMenuOption(
                icon: viewModel.favorite ? Icons.heart_broken : Icons.favorite,
                title: viewModel.favorite
                    ? "Remove from favorites"
                    : "Add to favorites",
                onSelected: () async {
                  final result = await viewModel.toggleFavorite();
                  if (!context.mounted) return;
                  toastResult(context, result);
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
                  title: "Go to release",
                  onSelected: widget.onGoToAlbum,
                ),
              if (widget.onGoToArtist != null)
                ContextMenuOption(
                  icon: Icons.person,
                  title: "Go to artist",
                  onSelected: widget.onGoToArtist,
                ),
              ContextMenuOption(
                title: "Info",
                icon: Icons.info_outline,
                onSelected: () {
                  MediaInfoDialog.showSong(context, widget.id);
                },
              ),
              if (widget.onRemove != null && !widget.removeButton)
                ContextMenuOption(
                  icon: Icons.playlist_remove,
                  title: "Remove",
                  onSelected: widget.onRemove,
                ),
            ],
            extraTrailing: [
              if (widget.onRemove != null && widget.removeButton)
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline),
                )
            ],
          );
        });
  }
}

class SongLeadingWidget extends StatelessWidget {
  final int? trackNr;
  final int? trackDigits;
  final String? coverId;
  final int? reorderIndex;

  final SongListItemViewModel viewModel;

  const SongLeadingWidget({
    super.key,
    this.trackNr,
    this.trackDigits,
    this.coverId,
    this.reorderIndex,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    Widget leading;
    if (trackNr != null) {
      leading = Center(
        child: viewModel.playbackStatus == null
            ? Text(
                trackNr!.toString().padLeft(trackDigits ?? 2, "0"),
                overflow: TextOverflow.ellipsis,
                style:
                    textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w500),
              )
            : IconButton(
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
              ),
      );
    } else {
      leading = Stack(
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
              child: const ColoredBox(color: Color.fromARGB(90, 0, 0, 0)),
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
                color: Colors.white,
              ),
            )
        ],
      );
    }
    leading = Padding(
      padding: const EdgeInsets.only(left: 4),
      child: SizedBox(
        width: 40,
        height: 40,
        child: leading,
      ),
    );
    if (reorderIndex != null) {
      leading = ReorderableDragStartListener(
        index: reorderIndex!,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.drag_handle),
            ),
            leading,
          ],
        ),
      );
    }
    return leading;
  }
}
