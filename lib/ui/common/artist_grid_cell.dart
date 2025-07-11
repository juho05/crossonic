import 'package:crossonic/ui/common/artist_grid_cell_viewmodel.dart';
import 'package:crossonic/ui/common/dialogs/media_info.dart';
import 'package:crossonic/ui/common/grid_cell.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ArtistGridCell extends StatefulWidget {
  final String id;
  final String name;
  final List<String> extraInfo;
  final String? coverId;

  final void Function()? onTap;
  final void Function()? onPlay;
  final void Function()? onShuffle;
  final void Function(bool priority)? onAddToQueue;
  final void Function()? onAddToPlaylist;

  const ArtistGridCell({
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
  });

  @override
  State<ArtistGridCell> createState() => _ArtistGridCellState();
}

class _ArtistGridCellState extends State<ArtistGridCell> {
  late final ArtistGridCellViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ArtistGridCellViewModel(
      favoritesRepository: context.read(),
      artistId: widget.id,
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
          ContextMenuOption(
            title: "Info",
            icon: Icons.info_outline,
            onSelected: () {
              MediaInfoDialog.showArtist(context, _viewModel.artistId);
            },
          )
        ];
        return GridCell(
          title: widget.name,
          coverId: widget.coverId,
          isFavorite: _viewModel.favorite,
          menuOptions: menuOptions,
          placeholderIcon: Icons.person,
          circularCover: true,
          extraInfo: widget.extraInfo,
          onTap: widget.onTap,
        );
      },
    );
  }
}
