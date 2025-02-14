import 'package:crossonic/ui/common/clickable_list_item_with_context_menu.dart';
import 'package:crossonic/ui/common/cover_art.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:crossonic/utils/format.dart';
import 'package:flutter/material.dart';

class SongListItem extends StatelessWidget {
  final String title;
  final String? artist;
  final String? album;
  final int? year;
  final int? trackNr;
  final String? coverId;
  final Duration? duration;

  final void Function()? onTap;
  final void Function(bool priority)? onAddToQueue;
  final void Function(bool favorite)? onSetFavoriteStatus;
  final void Function()? onAddToPlaylist;
  final void Function()? onGoToAlbum;
  final void Function()? onGoToArtist;
  final void Function()? onRemove;

  const SongListItem({
    super.key,
    required this.title,
    this.artist,
    this.album,
    this.year,
    this.trackNr,
    this.coverId,
    this.duration,
    this.onTap,
    this.onAddToQueue,
    this.onSetFavoriteStatus,
    this.onAddToPlaylist,
    this.onGoToAlbum,
    this.onGoToArtist,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // TODO
    final isFavorite = true;
    return ClickableListItemWithContextMenu(
      title: title,
      extraInfo: [
        if (artist != null) artist!,
        if (album != null) album!,
        if (year != null) year!.toString(),
      ],
      leading: trackNr != null
          ? Text(
              trackNr!.toString().padLeft(2, "0"),
              overflow: TextOverflow.ellipsis,
              style:
                  textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w500),
            )
          : SizedBox(
              height: 40,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: CoverArt(
                  placeholderIcon: Icons.album,
                  coverId: coverId,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
      trailingInfo: duration != null ? formatDuration(duration!) : null,
      onTap: onTap,
      isFavorite: isFavorite,
      options: [
        if (onAddToQueue != null)
          ContextMenuOption(
            icon: Icons.playlist_add,
            title: "Add to queue",
            onSelected: () => onAddToQueue!(false),
          ),
        if (onAddToQueue != null)
          ContextMenuOption(
            icon: Icons.playlist_play,
            title: "Add to priority queue",
            onSelected: () => onAddToQueue!(true),
          ),
        if (onSetFavoriteStatus != null)
          ContextMenuOption(
            icon: isFavorite ? Icons.heart_broken : Icons.favorite,
            title: isFavorite ? "Remove from favorites" : "Add to favorites",
            onSelected: () => onSetFavoriteStatus!(!isFavorite),
          ),
        if (onAddToPlaylist != null)
          ContextMenuOption(
            icon: Icons.playlist_add,
            title: "Add to playlist",
            onSelected: onAddToPlaylist,
          ),
        if (onGoToAlbum != null)
          ContextMenuOption(
            icon: Icons.album,
            title: "Go to album",
            onSelected: onGoToAlbum,
          ),
        if (onGoToArtist != null)
          ContextMenuOption(
            icon: Icons.person,
            title: "Go to artist",
            onSelected: onGoToArtist,
          ),
        if (onRemove != null)
          ContextMenuOption(
            icon: Icons.playlist_remove,
            title: "Remove",
            onSelected: onRemove,
          ),
      ],
    );
  }
}
