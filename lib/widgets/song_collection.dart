import 'dart:ui';

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

class SongCollection extends StatefulWidget {
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
  State<SongCollection> createState() => _SongCollectionState();
}

class _SongCollectionState extends State<SongCollection> {
  final _popupMenuButtonKey = GlobalKey<State>();

  List<PopupMenuItem<SongCollectionPopupMenuValue>> _getPopupMenuItems(
          BuildContext context, bool isFavorite) =>
      [
        if (widget.enablePlay && widget.getSongs != null)
          const PopupMenuItem(
            value: SongCollectionPopupMenuValue.play,
            child: ListTile(
              leading: Icon(Icons.play_arrow),
              title: Text('Play'),
            ),
          ),
        if (widget.enableShuffle && widget.getSongs != null)
          const PopupMenuItem(
            value: SongCollectionPopupMenuValue.shuffle,
            child: ListTile(
              leading: Icon(Icons.shuffle),
              title: Text('Shuffle'),
            ),
          ),
        if (widget.enableQueue && widget.getSongs != null)
          const PopupMenuItem(
            value: SongCollectionPopupMenuValue.addToPriorityQueue,
            child: ListTile(
              leading: Icon(Icons.playlist_play),
              title: Text('Add to priority queue'),
            ),
          ),
        if (widget.enableQueue && widget.getSongs != null)
          const PopupMenuItem(
            value: SongCollectionPopupMenuValue.addToQueue,
            child: ListTile(
              leading: Icon(Icons.playlist_add),
              title: Text('Add to queue'),
            ),
          ),
        if (widget.enablePlaylist && widget.getSongs != null)
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
            leading: Icon(isFavorite ? Icons.heart_broken : Icons.favorite),
            title:
                Text(isFavorite ? 'Remove from favorites' : 'Add to favorites'),
          ),
        ),
        if (widget.artists != null)
          const PopupMenuItem(
            value: SongCollectionPopupMenuValue.gotoArtist,
            child: ListTile(
              leading: Icon(Icons.person),
              title: Text('Go to artist'),
            ),
          ),
      ];

  void _onPopupMenuItemSelected(SongCollectionPopupMenuValue value) async {
    final audioHandler = context.read<CrossonicAudioHandler>();
    switch (value) {
      case SongCollectionPopupMenuValue.play:
        audioHandler.playOnNextMediaChange();
        audioHandler.mediaQueue.replaceQueue(await widget.getSongs!());
      case SongCollectionPopupMenuValue.shuffle:
        audioHandler.playOnNextMediaChange();
        audioHandler.mediaQueue.replaceQueue(await widget.getSongs!()
          ..shuffle());
      case SongCollectionPopupMenuValue.addToPriorityQueue:
        audioHandler.mediaQueue.addAllToPriorityQueue(await widget.getSongs!());
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Added "${widget.name}" to priority queue'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 1250),
          ));
        }
      case SongCollectionPopupMenuValue.addToQueue:
        audioHandler.mediaQueue.addAll(await widget.getSongs!());
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Added "${widget.name}" to queue'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 1250),
          ));
        }
      case SongCollectionPopupMenuValue.toggleFavorite:
        context.read<FavoritesCubit>().toggleFavorite(widget.id);
      case SongCollectionPopupMenuValue.addToPlaylist:
        await ChooserDialog.addToPlaylist(
            // ignore: use_build_context_synchronously
            context,
            widget.name,
            await widget.getSongs!());
      case SongCollectionPopupMenuValue.gotoArtist:
        final artistID = await ChooserDialog.chooseArtist(
            context, widget.artists!.artists.toList());
        if (artistID == null) {
          return;
        }
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          context.push("/home/artist/$artistID");
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return BlocBuilder<FavoritesCubit, FavoritesState>(
      buildWhen: (previous, current) => current.changedId == widget.id,
      builder: (context, state) {
        final isFavorite = state.favorites.contains(widget.id);
        Offset? mouseClickPosition;
        return GestureDetector(
          onSecondaryTapDown: (details) {
            if (details.kind != PointerDeviceKind.mouse) return;
            mouseClickPosition = details.globalPosition;
          },
          onSecondaryTap: () async {
            if (mouseClickPosition == null) return;
            final overlay = Overlay.of(context).context.findRenderObject();
            if (overlay == null) return;
            final popupButtonObject =
                _popupMenuButtonKey.currentContext?.findRenderObject();
            if (popupButtonObject == null) return;
            final result = showMenu(
                context: context,
                position: RelativeRect.fromRect(
                    Rect.fromLTWH(
                      mouseClickPosition!.dx,
                      mouseClickPosition!.dy,
                      popupButtonObject.paintBounds.width,
                      popupButtonObject.paintBounds.height,
                    ),
                    Rect.fromLTWH(0, 0, overlay.paintBounds.width,
                        overlay.paintBounds.height)),
                items: _getPopupMenuItems(context, isFavorite));
            mouseClickPosition = null;
            final option = await result;
            if (option != null) {
              _onPopupMenuItemSelected(option);
            }
          },
          child: ListTile(
            leading: CoverArt(
              size: 40,
              coverID: widget.coverID,
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
                        widget.name,
                        style: textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w400, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.artists != null ||
                          widget.genreText != null ||
                          widget.albumCount != null ||
                          widget.year != null)
                        Text(
                          [
                            if (widget.artists != null)
                              widget.artists!.displayName,
                            if (widget.genreText != null) widget.genreText,
                            if (widget.albumCount != null)
                              "Albums: ${widget.albumCount}",
                            if (widget.year != null) widget.year,
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
            contentPadding: widget.padding,
            trailing: PopupMenuButton<SongCollectionPopupMenuValue>(
              key: _popupMenuButtonKey,
              icon: const Icon(Icons.more_vert),
              onSelected: _onPopupMenuItemSelected,
              itemBuilder: (BuildContext context) =>
                  _getPopupMenuItems(context, isFavorite),
            ),
            onTap: widget.onTap,
          ),
        );
      },
    );
  }
}
