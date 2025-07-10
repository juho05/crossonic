import 'package:crossonic/ui/common/artist_list_item_viewmodel.dart';
import 'package:crossonic/ui/common/clickable_list_item_with_context_menu.dart';
import 'package:crossonic/ui/common/cover_art.dart';
import 'package:crossonic/ui/common/dialogs/chooser.dart';
import 'package:crossonic/ui/common/dialogs/media_info.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ArtistListItem extends StatefulWidget {
  final String id;
  final String name;
  final String? coverId;
  final int? albumCount;

  final void Function()? onTap;
  final void Function()? onPlay;
  final void Function(bool shuffleSongs)? onShuffle;
  final void Function(bool priority)? onAddToQueue;
  final void Function()? onAddToPlaylist;

  const ArtistListItem({
    super.key,
    required this.id,
    required this.name,
    this.coverId,
    this.albumCount,
    this.onTap,
    this.onPlay,
    this.onShuffle,
    this.onAddToQueue,
    this.onAddToPlaylist,
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
      artistId: widget.id,
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
            title: widget.name,
            extraInfo: [
              if (widget.albumCount != null) "Releases: ${widget.albumCount}",
            ],
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: SizedBox(
                width: 40,
                height: 40,
                child: CoverArt(
                  placeholderIcon: Icons.album,
                  coverId: widget.coverId,
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
            ),
            onTap: widget.onTap,
            isFavorite: viewModel.favorite,
            options: [
              if (widget.onPlay != null)
                ContextMenuOption(
                  icon: Icons.play_arrow,
                  title: "Play",
                  onSelected: widget.onPlay,
                ),
              if (widget.onShuffle != null)
                ContextMenuOption(
                  icon: Icons.shuffle,
                  title: "Shuffle",
                  onSelected: () async {
                    final option = await ChooserDialog.choose(
                        context, "Shuffle", ["Releases", "Songs"]);
                    if (option == null) return;
                    widget.onShuffle!(option == 1);
                  },
                ),
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
              ContextMenuOption(
                title: "Info",
                icon: Icons.info_outline,
                onSelected: () {
                  MediaInfoDialog.showArtist(context, viewModel.artistId);
                },
              ),
            ],
          );
        });
  }
}
