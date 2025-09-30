import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/clickable_list_item_with_context_menu.dart';
import 'package:crossonic/ui/common/cover_art.dart';
import 'package:crossonic/ui/common/dialogs/add_to_playlist.dart';
import 'package:crossonic/ui/common/dialogs/chooser.dart';
import 'package:crossonic/ui/common/dialogs/media_info.dart';
import 'package:crossonic/ui/common/song_list_item_viewmodel.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:crossonic/utils/format.dart';
import 'package:crossonic/utils/result.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SongListItem extends StatefulWidget {
  final Song song;

  final bool showArtist;
  final bool showAlbum;
  final bool showYear;
  final bool showBpm;
  final bool showTrackNr;
  final int fallbackTrackNr;
  final int trackDigits;
  final bool showDuration;
  final int? reorderIndex;

  final bool showPlaybackStatus;
  final bool editMode;
  final bool enableLongPressReorder;
  final bool showDragHandle;
  final bool showRemoveButton;
  final DownloadStatus downloadStatus;

  final void Function(bool ctrlPressed)? onTap;
  final bool disableGoToAlbum;
  final bool disableGoToArtist;

  final void Function()? onRemove;

  const SongListItem({
    super.key,
    required this.song,
    this.showArtist = true,
    this.showAlbum = false,
    this.showYear = true,
    this.showBpm = false,
    this.showTrackNr = false,
    this.fallbackTrackNr = 0,
    this.trackDigits = 2,
    this.showDuration = true,
    this.showPlaybackStatus = true,
    this.editMode = false,
    this.enableLongPressReorder = false,
    this.showDragHandle = false,
    this.showRemoveButton = false,
    this.downloadStatus = DownloadStatus.none,
    this.disableGoToAlbum = false,
    this.disableGoToArtist = false,
    this.onTap,
    this.onRemove,
    this.reorderIndex,
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
      song: widget.song,
      disablePlaybackStatus: !widget.showPlaybackStatus,
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
          final s = widget.song;
          return ReorderableDelayedDragStartListener(
            index: widget.reorderIndex ?? 0,
            enabled:
                widget.enableLongPressReorder && widget.reorderIndex != null,
            child: ClickableListItemWithContextMenu(
              title: widget.song.title,
              titleBold: viewModel.playbackStatus != null,
              extraInfo: [
                if (widget.showArtist) s.displayArtist,
                if (widget.showAlbum) s.album?.name ?? "Unknown album",
                if (widget.showYear)
                  s.originalDate?.year.toString() ?? "Unknown year",
                if (widget.showBpm)
                  s.bpm != null ? "${s.bpm} BPM" : "Unknown bpm",
              ],
              leading: SongLeadingWidget(
                viewModel: viewModel,
                coverId: s.coverId,
                trackNr: widget.showTrackNr
                    ? s.trackNr ?? widget.fallbackTrackNr
                    : null,
                trackDigits: widget.trackDigits,
                reorderIndex: widget.reorderIndex,
                showDragHandle: widget.showDragHandle,
              ),
              trailingInfo: widget.showDuration
                  ? (s.duration != null ? formatDuration(s.duration!) : "??:??")
                  : null,
              onTap: widget.onTap != null
                  ? () {
                      if (!widget.editMode) {
                        widget
                            .onTap!(HardwareKeyboard.instance.isControlPressed);
                      }
                    }
                  : null,
              isFavorite: viewModel.favorite,
              downloadStatus: widget.downloadStatus,
              options: widget.editMode
                  ? const []
                  : [
                      ContextMenuOption(
                        icon: Icons.playlist_play,
                        title: "Add to priority queue",
                        onSelected: () {
                          viewModel.addToQueue(true);
                          Toast.show(
                              context, "Added '${s.title}' to priority queue");
                        },
                      ),
                      ContextMenuOption(
                        icon: Icons.playlist_add,
                        title: "Add to queue",
                        onSelected: () {
                          viewModel.addToQueue(false);
                          Toast.show(context, "Added '${s.title}' to queue");
                        },
                      ),
                      ContextMenuOption(
                        icon: viewModel.favorite
                            ? Icons.heart_broken
                            : Icons.favorite,
                        title: viewModel.favorite
                            ? "Remove from favorites"
                            : "Add to favorites",
                        onSelected: () async {
                          final result = await viewModel.toggleFavorite();
                          if (!context.mounted) return;
                          toastResult(context, result);
                        },
                      ),
                      ContextMenuOption(
                          icon: Icons.playlist_add,
                          title: "Add to playlist",
                          onSelected: () {
                            AddToPlaylistDialog.show(
                                context, s.title, () async => Result.ok([s]));
                          }),
                      if (!widget.disableGoToAlbum && s.album != null)
                        ContextMenuOption(
                          icon: Icons.album,
                          title: "Go to release",
                          onSelected: () {
                            context.router
                                .push(AlbumRoute(albumId: s.album!.id));
                          },
                        ),
                      if (!widget.disableGoToArtist && s.artists.isNotEmpty)
                        ContextMenuOption(
                          icon: Icons.person,
                          title: "Go to artist",
                          onSelected: () async {
                            final router = context.router;
                            final artistId = await ChooserDialog.chooseArtist(
                                context, s.artists.toList());
                            if (artistId == null) return;
                            router.push(ArtistRoute(artistId: artistId));
                          },
                        ),
                      ContextMenuOption(
                        title: "Info",
                        icon: Icons.info_outline,
                        onSelected: () {
                          MediaInfoDialog.showSong(context, s.id);
                        },
                      ),
                      if (widget.onRemove != null && !widget.showRemoveButton)
                        ContextMenuOption(
                          icon: Icons.playlist_remove,
                          title: "Remove",
                          onSelected: widget.onRemove,
                        ),
                    ],
              extraTrailing: [
                if (widget.onRemove != null && widget.showRemoveButton)
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete_outline),
                  )
              ],
            ),
          );
        });
  }
}

class SongLeadingWidget extends StatelessWidget {
  final int? trackNr;
  final int? trackDigits;
  final String? coverId;
  final int? reorderIndex;
  final bool showDragHandle;

  final SongListItemViewModel viewModel;

  const SongLeadingWidget({
    super.key,
    this.trackNr,
    this.trackDigits,
    this.coverId,
    this.reorderIndex,
    this.showDragHandle = false,
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
    if (reorderIndex != null && showDragHandle) {
      leading = ReorderableDragStartListener(
        index: reorderIndex!,
        child: Material(
          color: Colors.transparent,
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
        ),
      );
    }
    return leading;
  }
}
