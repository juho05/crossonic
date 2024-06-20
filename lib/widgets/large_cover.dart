import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:crossonic/repositories/api/models/media_model.dart';
import 'package:crossonic/services/audio_handler/audio_handler.dart';
import 'package:crossonic/widgets/chooser.dart';
import 'package:crossonic/widgets/cover_art.dart';
import 'package:crossonic/widgets/state/favorites_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:icon_decoration/icon_decoration.dart';

enum LargeCoverPopupMenuValue {
  play,
  shuffle,
  addToPriorityQueue,
  addToQueue,
  toggleFavorite,
  addToPlaylist,
  gotoAlbum,
  gotoArtist,
  edit,
  delete,
}

enum ChangeCoverPopupMenuValue {
  change,
  remove,
}

class CoverArtWithMenu extends StatelessWidget {
  final String id;
  final String? coverID;
  final double size;
  final CoverResolution resolution;
  final double borderRadius;
  final bool isFavorite;
  final String name;
  final String? albumID;
  final List<ArtistIDName>? artists;
  final Future<List<Media>> Function()? getSongs;
  final Future<List<Media>?> Function()? getSongsShuffled;
  final void Function()? onGoTo;
  final void Function()? onEdit;
  final void Function()? onChangePicture;
  final void Function()? onRemovePicture;
  final bool editing;
  final void Function()? onDelete;

  final bool enablePlay;
  final bool enableShuffle;
  final bool enableQueue;
  final bool enableToggleFavorite;
  final bool enablePlaylist;

  final bool uploading;

  const CoverArtWithMenu({
    super.key,
    required this.id,
    required this.size,
    required this.name,
    this.coverID,
    this.resolution = const CoverResolution.large(),
    this.borderRadius = 7,
    this.isFavorite = false,
    this.albumID,
    this.artists,
    this.getSongs,
    this.getSongsShuffled,
    this.onGoTo,
    this.onEdit,
    this.onChangePicture,
    this.onRemovePicture,
    this.editing = false,
    this.onDelete,
    this.enablePlay = false,
    this.enableShuffle = false,
    this.enableQueue = true,
    this.enableToggleFavorite = true,
    this.enablePlaylist = true,
    this.uploading = false,
  });

  @override
  Widget build(BuildContext context) {
    final largeLayout = size > 256;
    return Stack(
      children: [
        if (uploading)
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator.adaptive(),
          ),
        if (!uploading)
          CoverArt(
            coverID: coverID,
            resolution: resolution,
            borderRadius: BorderRadius.circular(borderRadius),
            size: size,
          ),
        SizedBox(
          width: size,
          height: size,
          child: Padding(
            padding: EdgeInsets.all(largeLayout ? 10 : 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: isFavorite
                      ? DecoratedIcon(
                          decoration: const IconDecoration(
                              border: IconBorder(
                                  color: Color.fromARGB(255, 199, 101, 81),
                                  width: 3)),
                          icon: Icon(
                            Icons.favorite,
                            shadows: const [
                              Shadow(blurRadius: 2, color: Colors.black45),
                            ],
                            size: largeLayout ? 26 : 20,
                            color: const Color.fromARGB(255, 248, 248, 248),
                          ),
                        )
                      : null,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (onChangePicture != null && onRemovePicture == null)
                      Material(
                        type: MaterialType.transparency,
                        child: Ink(
                          decoration: ShapeDecoration(
                            color: Colors.black.withOpacity(0.35),
                            shape: const CircleBorder(),
                          ),
                          child: SizedBox(
                            width: largeLayout ? 40 : 30,
                            height: largeLayout ? 40 : 30,
                            child: IconButton(
                              icon:
                                  Icon(Icons.edit, size: largeLayout ? 26 : 20),
                              padding: const EdgeInsets.all(0),
                              onPressed: () {
                                onChangePicture!();
                              },
                            ),
                          ),
                        ),
                      ),
                    if (onChangePicture != null && onRemovePicture != null)
                      Material(
                        type: MaterialType.transparency,
                        child: Ink(
                          decoration: ShapeDecoration(
                            color: Colors.black.withOpacity(0.35),
                            shape: const CircleBorder(),
                          ),
                          child: SizedBox(
                            width: largeLayout ? 40 : 30,
                            height: largeLayout ? 40 : 30,
                            child: PopupMenuButton<ChangeCoverPopupMenuValue>(
                              icon:
                                  Icon(Icons.edit, size: largeLayout ? 26 : 20),
                              padding: const EdgeInsets.all(0),
                              onSelected: (value) {
                                if (value == ChangeCoverPopupMenuValue.change) {
                                  onChangePicture!();
                                } else if (value ==
                                    ChangeCoverPopupMenuValue.remove) {
                                  onRemovePicture!();
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                const PopupMenuItem(
                                  value: ChangeCoverPopupMenuValue.change,
                                  child: ListTile(
                                    leading: Icon(Icons.edit),
                                    title: Text('Change'),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: ChangeCoverPopupMenuValue.remove,
                                  child: ListTile(
                                    leading: Icon(Icons.delete_outline),
                                    title: Text('Remove'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (onChangePicture == null) const SizedBox(),
                    Material(
                      type: MaterialType.transparency,
                      child: Ink(
                        decoration: ShapeDecoration(
                          color: Colors.black.withOpacity(0.35),
                          shape: const CircleBorder(),
                        ),
                        child: SizedBox(
                            width: largeLayout ? 40 : 30,
                            height: largeLayout ? 40 : 30,
                            child: PopupMenuButton<LargeCoverPopupMenuValue>(
                              icon: Icon(Icons.more_vert,
                                  size: largeLayout ? 26 : 20),
                              padding: const EdgeInsets.all(0),
                              iconColor:
                                  const Color.fromARGB(255, 248, 248, 248),
                              onSelected: (value) async {
                                final audioHandler =
                                    context.read<CrossonicAudioHandler>();
                                switch (value) {
                                  case LargeCoverPopupMenuValue.play:
                                    audioHandler.playOnNextMediaChange();
                                    audioHandler.mediaQueue
                                        .replaceQueue(await getSongs!());
                                  case LargeCoverPopupMenuValue.shuffle:
                                    final songs = getSongsShuffled != null
                                        ? await getSongsShuffled!()
                                        : (await getSongs!()
                                          ..shuffle());
                                    if (songs == null) return;
                                    audioHandler.playOnNextMediaChange();
                                    audioHandler.mediaQueue.replaceQueue(songs);
                                  case LargeCoverPopupMenuValue
                                        .addToPriorityQueue:
                                    audioHandler.mediaQueue
                                        .addAllToPriorityQueue(
                                            await getSongs!());
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                            'Added "$name" to priority queue'),
                                        behavior: SnackBarBehavior.floating,
                                        duration:
                                            const Duration(milliseconds: 1250),
                                      ));
                                    }
                                  case LargeCoverPopupMenuValue.addToQueue:
                                    audioHandler.mediaQueue
                                        .addAll(await getSongs!());
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text('Added "$name" to queue'),
                                        behavior: SnackBarBehavior.floating,
                                        duration:
                                            const Duration(milliseconds: 1250),
                                      ));
                                    }
                                  case LargeCoverPopupMenuValue.toggleFavorite:
                                    context
                                        .read<FavoritesCubit>()
                                        .toggleFavorite(id);
                                  case LargeCoverPopupMenuValue.addToPlaylist:
                                    await ChooserDialog.addToPlaylist(
                                        // ignore: use_build_context_synchronously
                                        context,
                                        name,
                                        await getSongs!());
                                  case LargeCoverPopupMenuValue.gotoAlbum:
                                    if (albumID == null) {
                                      return;
                                    }
                                    context.push("/home/album/$albumID");
                                    if (onGoTo != null) onGoTo!();
                                  case LargeCoverPopupMenuValue.gotoArtist:
                                    final artistID =
                                        await ChooserDialog.chooseArtist(
                                            context, artists!);
                                    if (artistID == null) {
                                      return;
                                    }
                                    if (context.mounted) {
                                      context.push("/home/artist/$artistID");
                                      if (onGoTo != null) onGoTo!();
                                    }
                                  case LargeCoverPopupMenuValue.edit:
                                    onEdit!();
                                  case LargeCoverPopupMenuValue.delete:
                                    onDelete!();
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                if (enablePlay && getSongs != null)
                                  const PopupMenuItem(
                                    value: LargeCoverPopupMenuValue.play,
                                    child: ListTile(
                                      leading: Icon(Icons.play_arrow),
                                      title: Text('Play'),
                                    ),
                                  ),
                                if (enableShuffle && getSongs != null)
                                  const PopupMenuItem(
                                    value: LargeCoverPopupMenuValue.shuffle,
                                    child: ListTile(
                                      leading: Icon(Icons.shuffle),
                                      title: Text('Shuffle'),
                                    ),
                                  ),
                                if (enableQueue && getSongs != null)
                                  const PopupMenuItem(
                                    value: LargeCoverPopupMenuValue
                                        .addToPriorityQueue,
                                    child: ListTile(
                                      leading: Icon(Icons.playlist_play),
                                      title: Text('Add to priority queue'),
                                    ),
                                  ),
                                if (enableQueue && getSongs != null)
                                  const PopupMenuItem(
                                    value: LargeCoverPopupMenuValue.addToQueue,
                                    child: ListTile(
                                      leading: Icon(Icons.playlist_add),
                                      title: Text('Add to queue'),
                                    ),
                                  ),
                                if (enableToggleFavorite)
                                  PopupMenuItem(
                                    value:
                                        LargeCoverPopupMenuValue.toggleFavorite,
                                    child: ListTile(
                                      leading: Icon(isFavorite
                                          ? Icons.heart_broken
                                          : Icons.favorite),
                                      title: Text(isFavorite
                                          ? 'Remove from favorites'
                                          : 'Add to favorites'),
                                    ),
                                  ),
                                if (enablePlaylist && getSongs != null)
                                  const PopupMenuItem(
                                    value:
                                        LargeCoverPopupMenuValue.addToPlaylist,
                                    child: ListTile(
                                      leading: Icon(Icons.playlist_add),
                                      title: Text('Add to playlist'),
                                    ),
                                  ),
                                if (albumID != null)
                                  const PopupMenuItem(
                                    value: LargeCoverPopupMenuValue.gotoAlbum,
                                    child: ListTile(
                                      leading: Icon(Icons.person),
                                      title: Text('Go to album'),
                                    ),
                                  ),
                                if (artists?.isNotEmpty ?? false)
                                  const PopupMenuItem(
                                    value: LargeCoverPopupMenuValue.gotoArtist,
                                    child: ListTile(
                                      leading: Icon(Icons.person),
                                      title: Text('Go to artist'),
                                    ),
                                  ),
                                if (onEdit != null)
                                  PopupMenuItem(
                                    value: LargeCoverPopupMenuValue.edit,
                                    child: ListTile(
                                      leading: editing
                                          ? const Icon(Icons.edit_off)
                                          : const Icon(Icons.edit),
                                      title: editing
                                          ? const Text('Stop editing')
                                          : const Text("Edit"),
                                    ),
                                  ),
                                if (onDelete != null)
                                  const PopupMenuItem(
                                    value: LargeCoverPopupMenuValue.delete,
                                    child: ListTile(
                                      leading: Icon(Icons.delete_outline),
                                      title: Text('Delete'),
                                    ),
                                  ),
                              ],
                            )),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
