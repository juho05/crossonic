import 'package:crossonic/widgets/cover_art.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum SongCollectionPopupMenuValue { addToPriorityQueue, addToQueue, gotoArtist }

class SongCollection extends StatelessWidget {
  final String name;
  final String? coverID;
  final String? artistID;
  final String? artist;
  final String? genre;
  final int? albumCount;
  final int? year;
  final void Function()? onTap;
  final void Function()? onAddToQueue;
  final void Function()? onAddToPriorityQueue;
  final EdgeInsetsGeometry padding;
  const SongCollection({
    super.key,
    required this.name,
    this.onTap,
    this.onAddToPriorityQueue,
    this.onAddToQueue,
    this.artist,
    this.artistID,
    this.genre,
    this.albumCount,
    this.year,
    this.padding = const EdgeInsets.only(left: 16, right: 5),
    this.coverID,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      leading: coverID != null
          ? CoverArt(
              size: 40,
              coverID: coverID!,
              resolution: const CoverResolution.tiny(),
              borderRadius: BorderRadius.circular(5),
            )
          : null,
      title: Row(
        children: [
          Expanded(
              child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: textTheme.bodyMedium!
                      .copyWith(fontWeight: FontWeight.w400, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
                if (artist != null ||
                    genre != null ||
                    albumCount != null ||
                    year != null)
                  Text(
                    [
                      if (artist != null) artist,
                      if (genre != null) genre,
                      if (albumCount != null) "Albums: $albumCount",
                      if (year != null) year,
                    ].join(" • "),
                    style: textTheme.bodySmall!
                        .copyWith(fontWeight: FontWeight.w300, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          )),
          if (false) const Icon(Icons.favorite, size: 15),
        ],
      ),
      horizontalTitleGap: 0,
      contentPadding: padding,
      trailing: PopupMenuButton<SongCollectionPopupMenuValue>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          switch (value) {
            case SongCollectionPopupMenuValue.addToPriorityQueue:
              if (onAddToPriorityQueue != null) onAddToPriorityQueue!();
            case SongCollectionPopupMenuValue.addToQueue:
              if (onAddToQueue != null) onAddToQueue!();
            case SongCollectionPopupMenuValue.gotoArtist:
              context.push("/home/artist/$artistID");
          }
        },
        itemBuilder: (BuildContext context) => [
          if (onAddToPriorityQueue != null)
            const PopupMenuItem(
              value: SongCollectionPopupMenuValue.addToPriorityQueue,
              child: ListTile(
                leading: Icon(Icons.playlist_play),
                title: Text('Add to priority queue'),
              ),
            ),
          if (onAddToQueue != null)
            const PopupMenuItem(
              value: SongCollectionPopupMenuValue.addToQueue,
              child: ListTile(
                leading: Icon(Icons.playlist_add),
                title: Text('Add to queue'),
              ),
            ),
          if (artistID != null)
            const PopupMenuItem(
              value: SongCollectionPopupMenuValue.gotoArtist,
              child: ListTile(
                leading: Icon(Icons.person),
                title: Text('Go to artist'),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}
