import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/album_list_item_viewmodel.dart';
import 'package:crossonic/ui/common/clickable_list_item_with_context_menu.dart';
import 'package:crossonic/ui/common/cover_art.dart';
import 'package:crossonic/ui/common/dialogs/add_to_playlist.dart';
import 'package:crossonic/ui/common/dialogs/chooser.dart';
import 'package:crossonic/ui/common/dialogs/media_info.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AlbumListItem extends StatefulWidget {
  final Album album;
  final bool showArtist;
  final bool showYear;
  final bool showSongCount;
  final bool disableGoToArtist;
  final bool transparent;
  final bool showReleaseVersion;

  final void Function()? onNavigate;

  const AlbumListItem({
    super.key,
    required this.album,
    this.showArtist = true,
    this.showYear = true,
    this.showSongCount = true,
    this.disableGoToArtist = false,
    this.transparent = false,
    this.showReleaseVersion = false,
    this.onNavigate,
  });

  @override
  State<AlbumListItem> createState() => _AlbumListItemState();
}

class _AlbumListItemState extends State<AlbumListItem> {
  late final AlbumListItemViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = AlbumListItemViewModel(
      favoritesRepository: context.read(),
      subsonicRepository: context.read(),
      audioHandler: context.read(),
      album: widget.album,
    );
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.album;

    String year = "Unknown year";
    if (widget.showReleaseVersion) {
      year = a.releaseDate?.toString() ??
          a.originalDate?.toString() ??
          "Unknown date";
    } else {
      if (a.originalDate != null) {
        year = a.originalDate!.year.toString();
      }
      if (a.releaseDate != null &&
          a.releaseDate!.year != a.originalDate!.year) {
        year += "/${a.releaseDate!.year}";
      }
    }

    return ListenableBuilder(
        listenable: viewModel,
        builder: (context, snapshot) {
          return ClickableListItemWithContextMenu(
            title: a.name,
            transparent: widget.transparent,
            extraInfo: [
              if (widget.showArtist) a.displayArtist,
              if (widget.showReleaseVersion && a.version != null) a.version!,
              if (widget.showYear) year,
            ],
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: SizedBox(
                width: 40,
                height: 40,
                child: CoverArt(
                  placeholderIcon: Icons.album,
                  coverId: a.coverId,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            trailingInfo: widget.showSongCount ? a.songCount.toString() : null,
            onTap: () {
              if (widget.onNavigate != null) {
                widget.onNavigate!();
              }
              context.router.push(AlbumRoute(albumId: a.id));
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
                  final result = await viewModel.play(shuffle: true);
                  if (!context.mounted) return;
                  toastResult(context, result);
                },
              ),
              ContextMenuOption(
                icon: Icons.playlist_play,
                title: "Add to priority queue",
                onSelected: () async {
                  final result = await viewModel.addToQueue(true);
                  if (!context.mounted) return;
                  toastResult(context, result,
                      successMsg: "Added '${a.name}' to priority queue");
                },
              ),
              ContextMenuOption(
                icon: Icons.playlist_add,
                title: "Add to queue",
                onSelected: () async {
                  final result = await viewModel.addToQueue(false);
                  if (!context.mounted) return;
                  toastResult(context, result,
                      successMsg: "Added '${a.name}' to queue");
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
                  if (widget.onNavigate != null) {
                    widget.onNavigate!();
                  }
                  AddToPlaylistDialog.show(context, a.name, viewModel.getSongs);
                },
              ),
              if (!widget.disableGoToArtist && a.artists.isNotEmpty)
                ContextMenuOption(
                  icon: Icons.person,
                  title: "Go to artist",
                  onSelected: () async {
                    final artistId = await ChooserDialog.chooseArtist(
                        context, a.artists.toList());
                    if (artistId == null || !context.mounted) {
                      return;
                    }
                    if (widget.onNavigate != null) {
                      widget.onNavigate!();
                    }
                    context.router.push(ArtistRoute(artistId: artistId));
                  },
                ),
              ContextMenuOption(
                title: "Info",
                icon: Icons.info_outline,
                onSelected: () {
                  MediaInfoDialog.showAlbum(context, a.id);
                },
              ),
            ],
          );
        });
  }
}
