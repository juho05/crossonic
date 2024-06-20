import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:crossonic/repositories/api/models/media_model.dart';
import 'package:crossonic/services/audio_handler/audio_handler.dart';
import 'package:crossonic/widgets/chooser.dart';
import 'package:crossonic/widgets/cover_art.dart';
import 'package:crossonic/widgets/state/favorites_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

enum SongCollectionPopupMenuValue {
  play,
  shuffle,
  addToPriorityQueue,
  addToQueue,
  toggleFavorite,
  addToPlaylist,
  gotoArtist
}

class SongCollection extends StatelessWidget {
  final String id;
  final String name;
  final String? coverID;
  final String? genreText;
  final int? albumCount;
  final int? year;
  final void Function()? onTap;
  final EdgeInsetsGeometry padding;

  final String? albumID;
  final Artists? artists;
  final Future<List<Media>> Function()? getSongs;

  final bool enablePlay;
  final bool enableShuffle;
  final bool enableQueue;
  final bool enablePlaylist;

  const SongCollection({
    super.key,
    required this.id,
    required this.name,
    this.onTap,
    this.genreText,
    this.albumCount,
    this.year,
    this.padding = const EdgeInsets.only(left: 16, right: 5),
    this.coverID,
    this.albumID,
    this.artists,
    this.getSongs,
    this.enablePlay = false,
    this.enableShuffle = false,
    this.enableQueue = true,
    this.enablePlaylist = true,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return BlocBuilder<FavoritesCubit, FavoritesState>(
      buildWhen: (previous, current) => current.changedId == id,
      builder: (context, state) {
        final isFavorite = state.favorites.contains(id);
        return ListTile(
          leading: CoverArt(
            size: 40,
            coverID: coverID,
            resolution: const CoverResolution.tiny(),
            borderRadius: BorderRadius.circular(5),
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
                      name,
                      style: textTheme.bodyMedium!
                          .copyWith(fontWeight: FontWeight.w400, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (artists != null ||
                        genreText != null ||
                        albumCount != null ||
                        year != null)
                      Text(
                        [
                          if (artists != null) artists!.displayName,
                          if (genreText != null) genreText,
                          if (albumCount != null) "Albums: $albumCount",
                          if (year != null) year,
                        ].join(" • "),
                        style: textTheme.bodySmall!.copyWith(
                            fontWeight: FontWeight.w300, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              )),
              if (isFavorite) const Icon(Icons.favorite, size: 15),
            ],
          ),
          horizontalTitleGap: 0,
          contentPadding: padding,
          trailing: PopupMenuButton<SongCollectionPopupMenuValue>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              final audioHandler = context.read<CrossonicAudioHandler>();
              switch (value) {
                case SongCollectionPopupMenuValue.play:
                  audioHandler.playOnNextMediaChange();
                  audioHandler.mediaQueue.replaceQueue(await getSongs!());
                case SongCollectionPopupMenuValue.shuffle:
                  audioHandler.playOnNextMediaChange();
                  audioHandler.mediaQueue.replaceQueue(await getSongs!()
                    ..shuffle());
                case SongCollectionPopupMenuValue.addToPriorityQueue:
                  audioHandler.mediaQueue
                      .addAllToPriorityQueue(await getSongs!());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Added "$name" to priority queue'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(milliseconds: 1250),
                    ));
                  }
                case SongCollectionPopupMenuValue.addToQueue:
                  audioHandler.mediaQueue.addAll(await getSongs!());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Added "$name" to queue'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(milliseconds: 1250),
                    ));
                  }
                case SongCollectionPopupMenuValue.toggleFavorite:
                  context.read<FavoritesCubit>().toggleFavorite(id);
                case SongCollectionPopupMenuValue.addToPlaylist:
                  await ChooserDialog.addToPlaylist(
                      // ignore: use_build_context_synchronously
                      context,
                      name,
                      await getSongs!());
                case SongCollectionPopupMenuValue.gotoArtist:
                  final artistID = await ChooserDialog.chooseArtist(
                      context, artists!.artists.toList());
                  if (artistID == null) {
                    return;
                  }
                  if (context.mounted) {
                    context.push("/home/artist/$artistID");
                  }
              }
            },
            itemBuilder: (BuildContext context) => [
              if (enablePlay && getSongs != null)
                const PopupMenuItem(
                  value: SongCollectionPopupMenuValue.play,
                  child: ListTile(
                    leading: Icon(Icons.play_arrow),
                    title: Text('Play'),
                  ),
                ),
              if (enableShuffle && getSongs != null)
                const PopupMenuItem(
                  value: SongCollectionPopupMenuValue.shuffle,
                  child: ListTile(
                    leading: Icon(Icons.shuffle),
                    title: Text('Shuffle'),
                  ),
                ),
              if (enableQueue && getSongs != null)
                const PopupMenuItem(
                  value: SongCollectionPopupMenuValue.addToPriorityQueue,
                  child: ListTile(
                    leading: Icon(Icons.playlist_play),
                    title: Text('Add to priority queue'),
                  ),
                ),
              if (enableQueue && getSongs != null)
                const PopupMenuItem(
                  value: SongCollectionPopupMenuValue.addToQueue,
                  child: ListTile(
                    leading: Icon(Icons.playlist_add),
                    title: Text('Add to queue'),
                  ),
                ),
              if (enablePlaylist && getSongs != null)
                const PopupMenuItem(
                  value: SongCollectionPopupMenuValue.addToPlaylist,
                  child: ListTile(
                    leading: Icon(Icons.playlist_add),
                    title: Text('Add to playlist'),
                  ),
                ),
              PopupMenuItem(
                value: SongCollectionPopupMenuValue.toggleFavorite,
                child: ListTile(
                  leading:
                      Icon(isFavorite ? Icons.heart_broken : Icons.favorite),
                  title: Text(isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites'),
                ),
              ),
              if (artists != null)
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
      },
    );
  }
}
