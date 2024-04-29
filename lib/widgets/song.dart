import 'package:crossonic/repositories/subsonic/models/media_model.dart';
import 'package:crossonic/services/audio_player/audio_handler.dart';
import 'package:crossonic/widgets/cover_art.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

enum SongPopupMenuValue {
  addToPriorityQueue,
  addToQueue,
  remove,
  gotoAlbum,
  gotoArtist
}

enum SongLeadingItem { none, track, cover }

class Song extends StatelessWidget {
  final Media song;
  final SongLeadingItem leadingItem;
  final bool showArtist;
  final bool showAlbum;
  final bool showYear;
  final bool showGotoAlbum;
  final bool showGotoArtist;
  final bool showAddToQueue;
  final int? reorderIndex;
  final IconData? leadingIcon;
  final void Function()? onRemove;
  late final EdgeInsetsGeometry? padding;
  final void Function()? onTap;
  Song({
    super.key,
    required this.song,
    this.leadingItem = SongLeadingItem.none,
    this.showArtist = false,
    this.showAlbum = false,
    this.showYear = false,
    this.showGotoAlbum = true,
    this.showGotoArtist = true,
    this.showAddToQueue = true,
    this.leadingIcon,
    this.reorderIndex,
    this.onRemove,
    this.onTap,
    padding,
  }) {
    this.padding = padding ??
        EdgeInsets.only(
            left: reorderIndex != null || leadingIcon != null ? 8 : 16,
            right: 5);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final duration =
        song.duration != null ? Duration(seconds: song.duration!) : null;
    final leadingChildren = [
      if (leadingIcon != null)
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: SizedBox(height: 40, child: Icon(leadingIcon)),
        ),
      if (reorderIndex != null)
        const Padding(
          padding: EdgeInsets.only(right: 8.0),
          child: Icon(Icons.drag_handle),
        ),
      if (song.track != null && leadingItem == SongLeadingItem.track)
        Text(
          song.track.toString().padLeft(2, '0'),
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      if (song.coverArt != null && leadingItem == SongLeadingItem.cover)
        CoverArt(
          size: 40,
          coverID: song.coverArt!,
          resolution: const CoverResolution.tiny(),
          borderRadius: BorderRadius.circular(5),
        ),
    ];
    return ListTile(
      leading: reorderIndex == null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: leadingChildren,
            )
          : ReorderableDragStartListener(
              index: reorderIndex!,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: leadingChildren,
              ),
            ),
      title: Row(
        children: [
          Expanded(
              child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: textTheme.bodyMedium!
                      .copyWith(fontWeight: FontWeight.w400, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
                if (song.artist != null && showArtist ||
                    song.album != null && showAlbum ||
                    song.year != null && showYear)
                  Text(
                    [
                      if (song.artist != null && showArtist) song.artist,
                      if (song.album != null && showAlbum) song.album,
                      if (song.year != null && showYear) song.year.toString(),
                    ].join(" • "),
                    style: textTheme.bodySmall!
                        .copyWith(fontWeight: FontWeight.w300, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          )),
          if (song.starred != null) const Icon(Icons.favorite, size: 15),
          if (song.duration != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '${duration!.inHours > 0 ? '${duration.inHours}:' : ''}${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                style: textTheme.bodySmall,
              ),
            ),
        ],
      ),
      horizontalTitleGap: 0,
      contentPadding: padding,
      trailing: showAddToQueue ||
              onRemove != null ||
              showGotoAlbum ||
              showGotoArtist
          ? PopupMenuButton<SongPopupMenuValue>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                final audioHandler = context.read<CrossonicAudioHandler>();
                switch (value) {
                  case SongPopupMenuValue.addToPriorityQueue:
                    audioHandler.mediaQueue.addToPriorityQueue(song);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Added "${song.title}" to priority queue'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(milliseconds: 1250),
                    ));
                  case SongPopupMenuValue.addToQueue:
                    audioHandler.mediaQueue.add(song);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Added "${song.title}" to queue'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(milliseconds: 1250),
                    ));
                  case SongPopupMenuValue.remove:
                    onRemove!();
                  case SongPopupMenuValue.gotoAlbum:
                    context.push("/home/album/${song.albumId}");
                  case SongPopupMenuValue.gotoArtist:
                    context.push("/home/artist/${song.artistId}");
                }
              },
              itemBuilder: (BuildContext context) => [
                if (showAddToQueue)
                  const PopupMenuItem(
                    value: SongPopupMenuValue.addToPriorityQueue,
                    child: ListTile(
                      leading: Icon(Icons.playlist_play),
                      title: Text('Add to priority queue'),
                    ),
                  ),
                if (showAddToQueue)
                  const PopupMenuItem(
                    value: SongPopupMenuValue.addToQueue,
                    child: ListTile(
                      leading: Icon(Icons.playlist_add),
                      title: Text('Add to queue'),
                    ),
                  ),
                if (onRemove != null)
                  const PopupMenuItem(
                    value: SongPopupMenuValue.remove,
                    child: ListTile(
                      leading: Icon(Icons.playlist_remove),
                      title: Text('Remove'),
                    ),
                  ),
                if (showGotoAlbum && song.albumId != null)
                  const PopupMenuItem(
                    value: SongPopupMenuValue.gotoAlbum,
                    child: ListTile(
                      leading: Icon(Icons.album),
                      title: Text('Go to album'),
                    ),
                  ),
                if (showGotoArtist && song.artistId != null)
                  const PopupMenuItem(
                    value: SongPopupMenuValue.gotoArtist,
                    child: ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Go to artist'),
                    ),
                  ),
              ],
            )
          : const SizedBox(),
      onTap: onTap,
    );
  }
}
