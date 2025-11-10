import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/album_list_item_viewmodel.dart';
import 'package:crossonic/ui/common/album_release_badge.dart';
import 'package:crossonic/ui/common/dialogs/add_to_playlist.dart';
import 'package:crossonic/ui/common/dialogs/album_release_dialog.dart';
import 'package:crossonic/ui/common/dialogs/chooser.dart';
import 'package:crossonic/ui/common/dialogs/media_info.dart';
import 'package:crossonic/ui/common/grid_cell.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AlbumGridCell extends StatefulWidget {
  final Album album;
  final bool showArtist;
  final bool showYear;
  final bool disableGoToArtist;
  final List<Album>? alternatives;

  const AlbumGridCell({
    super.key,
    required this.album,
    this.showArtist = true,
    this.showYear = true,
    this.disableGoToArtist = false,
    this.alternatives,
  });

  @override
  State<AlbumGridCell> createState() => _AlbumGridCellState();
}

class _AlbumGridCellState extends State<AlbumGridCell> {
  late final AlbumListItemViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AlbumListItemViewModel(
      favoritesRepository: context.read(),
      audioHandler: context.read(),
      subsonicRepository: context.read(),
      album: widget.album,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.album;

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
          final result = await _viewModel.play(shuffle: true);
          if (!context.mounted) return;
          toastResult(context, result);
        },
      ),
      ContextMenuOption(
        title: "Add to priority queue",
        icon: Icons.playlist_play,
        onSelected: () async {
          final result = await _viewModel.addToQueue(true);
          if (!context.mounted) return;
          toastResult(
            context,
            result,
            successMsg: "Added '${a.name}' to priority queue",
          );
        },
      ),
      ContextMenuOption(
        title: "Add to queue",
        icon: Icons.playlist_add,
        onSelected: () async {
          final result = await _viewModel.addToQueue(false);
          if (!context.mounted) return;
          toastResult(
            context,
            result,
            successMsg: "Added '${a.name}' to queue",
          );
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
      if (!widget.disableGoToArtist && a.artists.isNotEmpty)
        ContextMenuOption(
          title: "Go to artist",
          icon: Icons.person,
          onSelected: () async {
            final artistId = await ChooserDialog.chooseArtist(
              context,
              a.artists.toList(),
            );
            if (artistId == null || !context.mounted) {
              return;
            }
            context.router.push(ArtistRoute(artistId: artistId));
          },
        ),
      ContextMenuOption(
        title: "Info",
        icon: Icons.info_outline,
        onSelected: () => MediaInfoDialog.showAlbum(context, a.id),
      ),
    ];

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return GridCell(
          menuOptions: menuOptions,
          coverId: a.coverId,
          isFavorite: _viewModel.favorite,
          placeholderIcon: Icons.album,
          title: a.name,
          extraInfo: [
            if (widget.showArtist) a.displayArtist,
            if (widget.showYear)
              a.originalDate?.year.toString() ?? "Unknown year",
          ],
          onTap: () {
            context.router.push(AlbumRoute(albumId: a.id));
          },
          topRight:
              (a.releaseDate != null &&
                  (a.originalDate!.year != a.releaseDate!.year ||
                      a.version != null))
              ? AlbumReleaseBadge(
                  albumId: a.id,
                  releaseDate: a.releaseDate,
                  albumVersion: a.version,
                  alternativeCount: widget.alternatives?.length,
                  onTap: () {
                    AlbumReleaseDialog.show(
                      context,
                      album: a,
                      alternatives: widget.alternatives,
                    );
                  },
                )
              : null,
        );
      },
    );
  }
}
