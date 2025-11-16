import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/subsonic/models/artist.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/artist_list_item_viewmodel.dart';
import 'package:crossonic/ui/common/clickable_list_item_with_context_menu.dart';
import 'package:crossonic/ui/common/cover_art.dart';
import 'package:crossonic/ui/common/dialogs/add_to_playlist.dart';
import 'package:crossonic/ui/common/dialogs/chooser.dart';
import 'package:crossonic/ui/common/dialogs/media_info.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ArtistListItem extends StatefulWidget {
  final Artist artist;
  final bool showAlbumCount;

  const ArtistListItem({
    super.key,
    required this.artist,
    this.showAlbumCount = true,
  });

  @override
  State<ArtistListItem> createState() => _ArtistListItemState();
}

class _ArtistListItemState extends State<ArtistListItem> {
  late final ArtistListItemViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = ArtistListItemViewModel(
      favoritesRepository: context.read(),
      audioHandler: context.read(),
      subsonicRepository: context.read(),
      artist: widget.artist,
    );
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.artist;
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, snapshot) {
        return ClickableListItemWithContextMenu(
          title: a.name,
          extraInfo: [
            if (widget.showAlbumCount && a.albumCount != null)
              "Releases: ${a.albumCount}",
          ],
          leading: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: CoverArt(
              size: 40,
              placeholderIcon: Icons.album,
              coverId: a.coverId,
              borderRadius: BorderRadius.circular(40),
            ),
          ),
          onTap: () {
            context.router.push(ArtistRoute(artistId: a.id));
          },
          isFavorite: viewModel.favorite,
          options: [
            ContextMenuOption(
              icon: Icons.play_arrow,
              title: "Play",
              onSelected: () async {
                final result = await viewModel.play();
                if (!context.mounted) return;
                toastResult(context, result);
              },
            ),
            ContextMenuOption(
              icon: Icons.shuffle,
              title: "Shuffle",
              onSelected: () async {
                final option = await ChooserDialog.choose(context, "Shuffle", [
                  "Releases",
                  "Songs",
                ]);
                if (option == null) return;
                final shuffleSongs = option == 1;
                final result = await viewModel.play(
                  shuffleAlbums: !shuffleSongs,
                  shuffleSongs: shuffleSongs,
                );
                if (!context.mounted) return;
                toastResult(context, result);
              },
            ),
            ContextMenuOption(
              icon: Icons.playlist_play,
              title: "Add to priority queue",
              onSelected: () async {
                final result = await viewModel.onAddToQueue(true);
                if (!context.mounted) return;
                toastResult(
                  context,
                  result,
                  successMsg: "Added '${a.name}' to priority queue",
                );
              },
            ),
            ContextMenuOption(
              icon: Icons.playlist_add,
              title: "Add to queue",
              onSelected: () async {
                final result = await viewModel.onAddToQueue(false);
                if (!context.mounted) return;
                toastResult(
                  context,
                  result,
                  successMsg: "Added '${a.name}' to queue",
                );
              },
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
            ContextMenuOption(
              icon: Icons.playlist_add,
              title: "Add to playlist",
              onSelected: () {
                AddToPlaylistDialog.show(context, a.name, viewModel.getSongs);
              },
            ),
            ContextMenuOption(
              title: "Info",
              icon: Icons.info_outline,
              onSelected: () {
                MediaInfoDialog.showArtist(context, viewModel.artist.id);
              },
            ),
          ],
        );
      },
    );
  }
}
