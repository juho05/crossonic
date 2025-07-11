import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
import 'package:crossonic/ui/common/dialogs/media_info.dart';
import 'package:crossonic/ui/common/grid_cell.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PlaylistGridCell extends StatefulWidget {
  final String id;
  final String name;
  final List<String> extraInfo;
  final String? coverId;
  final bool download;
  final DownloadStatus downloadStatus;

  final void Function()? onTap;
  final void Function()? onPlay;
  final void Function()? onShuffle;
  final void Function(bool priority)? onAddToQueue;
  final void Function()? onAddToPlaylist;
  final void Function()? onDelete;
  final void Function()? onToggleDownload;

  const PlaylistGridCell({
    super.key,
    required this.id,
    required this.name,
    required this.extraInfo,
    this.downloadStatus = DownloadStatus.none,
    this.coverId,
    required this.download,
    this.onTap,
    this.onPlay,
    this.onShuffle,
    this.onAddToQueue,
    this.onAddToPlaylist,
    this.onDelete,
    this.onToggleDownload,
  });

  @override
  State<PlaylistGridCell> createState() => _PlaylistGridCellState();
}

class _PlaylistGridCellState extends State<PlaylistGridCell> {
  @override
  Widget build(BuildContext context) {
    final menuOptions = [
      if (widget.onPlay != null)
        ContextMenuOption(
          title: "Play",
          icon: Icons.play_arrow,
          onSelected: widget.onPlay,
        ),
      if (widget.onShuffle != null)
        ContextMenuOption(
          title: "Shuffle",
          icon: Icons.shuffle,
          onSelected: widget.onShuffle,
        ),
      if (widget.onAddToQueue != null)
        ContextMenuOption(
          title: "Add to priority queue",
          icon: Icons.playlist_play,
          onSelected: () => widget.onAddToQueue!(true),
        ),
      if (widget.onAddToQueue != null)
        ContextMenuOption(
          title: "Add to queue",
          icon: Icons.playlist_add,
          onSelected: () => widget.onAddToQueue!(false),
        ),
      if (widget.onAddToQueue != null)
        ContextMenuOption(
          title: "Add to playlist",
          icon: Icons.playlist_add,
          onSelected: widget.onAddToPlaylist,
        ),
      if (widget.onToggleDownload != null && !kIsWeb)
        ContextMenuOption(
          title: widget.download ? "Remove Download" : "Download",
          icon: widget.download ? Icons.delete : Icons.download,
          onSelected: widget.onToggleDownload,
        ),
      ContextMenuOption(
        title: "Info",
        icon: Icons.info_outline,
        onSelected: () {
          MediaInfoDialog.showPlaylist(context, widget.id);
        },
      ),
      if (widget.onDelete != null)
        ContextMenuOption(
          title: "Delete",
          icon: Icons.delete_forever,
          onSelected: widget.onDelete,
        ),
    ];
    return GridCell(
      title: widget.name,
      coverId: widget.coverId,
      menuOptions: menuOptions,
      placeholderIcon: Icons.album,
      downloadStatus: widget.downloadStatus,
      extraInfo: widget.extraInfo,
      onTap: widget.onTap,
    );
  }
}
