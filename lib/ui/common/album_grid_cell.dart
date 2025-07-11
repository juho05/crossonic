import 'package:crossonic/ui/common/album_grid_cell_viewmodel.dart';
import 'package:crossonic/ui/common/dialogs/media_info.dart';
import 'package:crossonic/ui/common/grid_cell.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AlbumGridCell extends StatefulWidget {
  final String id;
  final String name;
  final List<String> extraInfo;
  final String? coverId;

  final void Function()? onTap;
  final void Function()? onPlay;
  final void Function()? onShuffle;
  final void Function(bool priority)? onAddToQueue;
  final void Function()? onAddToPlaylist;
  final void Function()? onGoToArtist;

  const AlbumGridCell({
    super.key,
    required this.id,
    required this.name,
    required this.extraInfo,
    this.coverId,
    this.onTap,
    this.onPlay,
    this.onShuffle,
    this.onAddToQueue,
    this.onAddToPlaylist,
    this.onGoToArtist,
  });

  @override
  State<AlbumGridCell> createState() => _AlbumGridCellState();
}

class _AlbumGridCellState extends State<AlbumGridCell> {
  late final AlbumGridCellViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AlbumGridCellViewModel(
      favoritesRepository: context.read(),
      albumId: widget.id,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
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
          ContextMenuOption(
            icon: _viewModel.favorite ? Icons.heart_broken : Icons.favorite,
            title: _viewModel.favorite
                ? "Remove from favorites"
                : "Add to favorites",
            onSelected: () async {
              final result = await _viewModel.toggleFavorite();
              if (!context.mounted) return;
              toastResult(context, result);
            },
          ),
          if (widget.onAddToQueue != null)
            ContextMenuOption(
              title: "Add to playlist",
              icon: Icons.playlist_add,
              onSelected: widget.onAddToPlaylist,
            ),
          if (widget.onGoToArtist != null)
            ContextMenuOption(
              title: "Go to artist",
              icon: Icons.person,
              onSelected: widget.onGoToArtist,
            ),
          ContextMenuOption(
            title: "Info",
            icon: Icons.info_outline,
            onSelected: () =>
                MediaInfoDialog.showAlbum(context, _viewModel.albumId),
          )
        ];
        return GridCell(
          menuOptions: menuOptions,
          coverId: widget.coverId,
          isFavorite: _viewModel.favorite,
          placeholderIcon: Icons.album,
          title: widget.name,
          extraInfo: widget.extraInfo,
          onTap: widget.onTap,
        );
      },
    );
  }
}
