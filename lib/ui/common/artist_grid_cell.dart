import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/subsonic/models/artist.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/artist_list_item_viewmodel.dart';
import 'package:crossonic/ui/common/dialogs/add_to_playlist.dart';
import 'package:crossonic/ui/common/dialogs/chooser.dart';
import 'package:crossonic/ui/common/dialogs/media_info.dart';
import 'package:crossonic/ui/common/grid_cell.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ArtistGridCell extends StatefulWidget {
  final Artist artist;
  final bool showReleaseCount;

  const ArtistGridCell({
    super.key,
    required this.artist,
    this.showReleaseCount = true,
  });

  @override
  State<ArtistGridCell> createState() => _ArtistGridCellState();
}

class _ArtistGridCellState extends State<ArtistGridCell> {
  late final ArtistListItemViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ArtistListItemViewModel(
      favoritesRepository: context.read(),
      audioHandler: context.read(),
      subsonicRepository: context.read(),
      artist: widget.artist,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.artist;
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final menuOptions = [
          ContextMenuOption(
            title: "Play",
            icon: Icons.play_arrow,
            onSelected: () async {
              final result = await _viewModel.play();
              if (!context.mounted) return;
              toastResult(context, result);
            },
          ),
          ContextMenuOption(
            title: "Shuffle",
            icon: Icons.shuffle,
            onSelected: () async {
              final option = await ChooserDialog.choose(
                  context, "Shuffle", ["Releases", "Songs"]);
              if (option == null) return;
              final shuffleSongs = option == 1;
              final result = await _viewModel.play(
                  shuffleAlbums: !shuffleSongs, shuffleSongs: shuffleSongs);
              if (!context.mounted) return;
              toastResult(context, result);
            },
          ),
          ContextMenuOption(
            title: "Add to priority queue",
            icon: Icons.playlist_play,
            onSelected: () async {
              final result = await _viewModel.onAddToQueue(true);
              if (!context.mounted) return;
              toastResult(context, result,
                  successMsg: "Added '${a.name}' to priority queue");
            },
          ),
          ContextMenuOption(
            title: "Add to queue",
            icon: Icons.playlist_add,
            onSelected: () async {
              final result = await _viewModel.onAddToQueue(false);
              if (!context.mounted) return;
              toastResult(context, result,
                  successMsg: "Added '${a.name}' to queue");
            },
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
          ContextMenuOption(
            title: "Add to playlist",
            icon: Icons.playlist_add,
            onSelected: () {
              AddToPlaylistDialog.show(context, a.name, _viewModel.getSongs);
            },
          ),
          ContextMenuOption(
            title: "Info",
            icon: Icons.info_outline,
            onSelected: () {
              MediaInfoDialog.showArtist(context, a.id);
            },
          )
        ];
        return GridCell(
          title: a.name,
          coverId: a.coverId,
          isFavorite: _viewModel.favorite,
          menuOptions: menuOptions,
          placeholderIcon: Icons.person,
          circularCover: true,
          extraInfo: [
            if (widget.showReleaseCount) "Releases: ${a.albumCount ?? "?"}"
          ],
          onTap: () {
            context.router.push(ArtistRoute(artistId: a.id));
          },
        );
      },
    );
  }
}
