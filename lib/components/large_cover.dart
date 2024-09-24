import 'dart:ui';

import 'package:crossonic/components/state/layout.dart';
import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:crossonic/repositories/api/models/media_model.dart';
import 'package:crossonic/services/audio_handler/audio_handler.dart';
import 'package:crossonic/components/chooser.dart';
import 'package:crossonic/components/cover_art.dart';
import 'package:crossonic/components/state/favorites_cubit.dart';
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
  toggleDownload,
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

class CoverArtWithMenu extends StatefulWidget {
  final String id;
  final String? coverID;
  final double size;
  final CoverResolution resolution;
  final double borderRadius;
  final bool isFavorite;
  final bool? downloadStatus;
  final String name;
  final String? albumID;
  final List<ArtistIDName>? artists;
  final Future<List<Media>> Function()? getSongs;
  final Future<List<Media>?> Function()? getSongsShuffled;
  final void Function()? onGoTo;
  final void Function()? onEdit;
  final void Function()? onChangePicture;
  final void Function()? onRemovePicture;
  final void Function()? onToggleDownload;
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
    this.downloadStatus,
    this.albumID,
    this.artists,
    this.getSongs,
    this.getSongsShuffled,
    this.onGoTo,
    this.onEdit,
    this.onChangePicture,
    this.onRemovePicture,
    this.onToggleDownload,
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
  State<CoverArtWithMenu> createState() => _CoverArtWithMenuState();
}

class _CoverArtWithMenuState extends State<CoverArtWithMenu> {
  final _popupMenuButtonKey = GlobalKey<State>();

  List<PopupMenuItem<LargeCoverPopupMenuValue>> _getPopupMenuItems(
          BuildContext context, bool isFavorite) =>
      [
        if (widget.enablePlay && widget.getSongs != null)
          const PopupMenuItem(
            value: LargeCoverPopupMenuValue.play,
            child: ListTile(
              leading: Icon(Icons.play_arrow),
              title: Text('Play'),
            ),
          ),
        if (widget.enableShuffle && widget.getSongs != null)
          const PopupMenuItem(
            value: LargeCoverPopupMenuValue.shuffle,
            child: ListTile(
              leading: Icon(Icons.shuffle),
              title: Text('Shuffle'),
            ),
          ),
        if (widget.enableQueue && widget.getSongs != null)
          const PopupMenuItem(
            value: LargeCoverPopupMenuValue.addToPriorityQueue,
            child: ListTile(
              leading: Icon(Icons.playlist_play),
              title: Text('Add to priority queue'),
            ),
          ),
        if (widget.enableQueue && widget.getSongs != null)
          const PopupMenuItem(
            value: LargeCoverPopupMenuValue.addToQueue,
            child: ListTile(
              leading: Icon(Icons.playlist_add),
              title: Text('Add to queue'),
            ),
          ),
        if (widget.enableToggleFavorite)
          PopupMenuItem(
            value: LargeCoverPopupMenuValue.toggleFavorite,
            child: ListTile(
              leading:
                  Icon(widget.isFavorite ? Icons.heart_broken : Icons.favorite),
              title: Text(widget.isFavorite
                  ? 'Remove from favorites'
                  : 'Add to favorites'),
            ),
          ),
        if (widget.onToggleDownload != null)
          PopupMenuItem(
            value: LargeCoverPopupMenuValue.toggleDownload,
            child: ListTile(
              leading: Icon(widget.downloadStatus == null
                  ? Icons.download
                  : Icons.delete_outline),
              title: Text(widget.downloadStatus == null
                  ? 'Download'
                  : 'Remove Download'),
            ),
          ),
        if (widget.enablePlaylist && widget.getSongs != null)
          const PopupMenuItem(
            value: LargeCoverPopupMenuValue.addToPlaylist,
            child: ListTile(
              leading: Icon(Icons.playlist_add),
              title: Text('Add to playlist'),
            ),
          ),
        if (widget.albumID != null)
          const PopupMenuItem(
            value: LargeCoverPopupMenuValue.gotoAlbum,
            child: ListTile(
              leading: Icon(Icons.person),
              title: Text('Go to album'),
            ),
          ),
        if (widget.artists?.isNotEmpty ?? false)
          const PopupMenuItem(
            value: LargeCoverPopupMenuValue.gotoArtist,
            child: ListTile(
              leading: Icon(Icons.person),
              title: Text('Go to artist'),
            ),
          ),
        if (widget.onEdit != null)
          PopupMenuItem(
            value: LargeCoverPopupMenuValue.edit,
            child: ListTile(
              leading: widget.editing
                  ? const Icon(Icons.edit_off)
                  : const Icon(Icons.edit),
              title: widget.editing
                  ? const Text('Stop editing')
                  : const Text("Edit"),
            ),
          ),
        if (widget.onDelete != null)
          const PopupMenuItem(
            value: LargeCoverPopupMenuValue.delete,
            child: ListTile(
              leading: Icon(Icons.delete_outline),
              title: Text('Delete'),
            ),
          ),
      ];

  void _onPopupMenuItemSelected(LargeCoverPopupMenuValue value) async {
    final audioHandler = context.read<CrossonicAudioHandler>();
    switch (value) {
      case LargeCoverPopupMenuValue.play:
        audioHandler.playOnNextMediaChange();
        audioHandler.mediaQueue.replaceQueue(await widget.getSongs!());
      case LargeCoverPopupMenuValue.shuffle:
        final songs = widget.getSongsShuffled != null
            ? await widget.getSongsShuffled!()
            : (await widget.getSongs!()
              ..shuffle());
        if (songs == null) return;
        audioHandler.playOnNextMediaChange();
        audioHandler.mediaQueue.replaceQueue(songs);
      case LargeCoverPopupMenuValue.addToPriorityQueue:
        audioHandler.mediaQueue.addAllToPriorityQueue(await widget.getSongs!());
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Added "${widget.name}" to priority queue'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 1250),
          ));
        }
      case LargeCoverPopupMenuValue.addToQueue:
        audioHandler.mediaQueue.addAll(await widget.getSongs!());
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Added "${widget.name}" to queue'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 1250),
          ));
        }
      case LargeCoverPopupMenuValue.toggleFavorite:
        context.read<FavoritesCubit>().toggleFavorite(widget.id);
      case LargeCoverPopupMenuValue.toggleDownload:
        widget.onToggleDownload!();
      case LargeCoverPopupMenuValue.addToPlaylist:
        await ChooserDialog.addToPlaylist(
            // ignore: use_build_context_synchronously
            context,
            widget.name,
            await widget.getSongs!());
      case LargeCoverPopupMenuValue.gotoAlbum:
        if (widget.albumID == null) {
          return;
        }
        context.push("/home/album/${widget.albumID}");
        if (widget.onGoTo != null) widget.onGoTo!();
      case LargeCoverPopupMenuValue.gotoArtist:
        final artistID =
            await ChooserDialog.chooseArtist(context, widget.artists!);
        if (artistID == null) {
          return;
        }
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          context.push("/home/artist/$artistID");
          if (widget.onGoTo != null) widget.onGoTo!();
        }
      case LargeCoverPopupMenuValue.edit:
        widget.onEdit!();
      case LargeCoverPopupMenuValue.delete:
        widget.onDelete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final largeLayout = widget.size > 256;
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
        final layout = context.read<Layout>();
        var mousePos = mouseClickPosition;
        if (layout.size == LayoutSize.desktop) {
          final double offset;
          if (MediaQuery.of(context).size.width > 1300) {
            offset = 180;
          } else {
            offset = 66;
          }
          if (mouseClickPosition!.dx < overlay.paintBounds.width * 0.5) {
            mousePos = mouseClickPosition!.translate(-offset, 0);
          }
        }
        final result = showMenu(
            context: context,
            position: RelativeRect.fromRect(
                Rect.fromLTWH(
                  mousePos!.dx,
                  mousePos.dy,
                  popupButtonObject.paintBounds.width,
                  popupButtonObject.paintBounds.height,
                ),
                Rect.fromLTWH(0, 0, overlay.paintBounds.width,
                    overlay.paintBounds.height)),
            items: _getPopupMenuItems(context, widget.isFavorite));
        mouseClickPosition = null;
        final option = await result;
        if (option != null) {
          _onPopupMenuItemSelected(option);
        }
      },
      child: Stack(
        children: [
          if (widget.uploading)
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: const CircularProgressIndicator.adaptive(),
            ),
          if (!widget.uploading)
            CoverArt(
              coverID: widget.coverID,
              resolution: widget.resolution,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              size: widget.size,
            ),
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: Padding(
              padding: EdgeInsets.all(largeLayout ? 10 : 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Visibility(
                        visible: widget.isFavorite,
                        child: DecoratedIcon(
                          decoration: IconDecoration(
                              border: IconBorder(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 4)),
                          icon: Icon(
                            Icons.favorite,
                            shadows: const [
                              Shadow(blurRadius: 2, color: Colors.black45),
                            ],
                            size: largeLayout ? 26 : 20,
                            color: const Color.fromARGB(255, 248, 248, 248),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: widget.downloadStatus != null,
                        child: DecoratedIcon(
                          icon: Icon(
                            widget.downloadStatus ?? false
                                ? Icons.download_for_offline_outlined
                                : Icons.downloading_outlined,
                            shadows: const [
                              Shadow(blurRadius: 3, color: Colors.black54),
                            ],
                            size: largeLayout ? 26 : 20,
                            color: const Color.fromARGB(255, 248, 248, 248),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.onChangePicture != null &&
                          widget.onRemovePicture == null)
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
                                icon: Icon(Icons.edit,
                                    size: largeLayout ? 26 : 20),
                                padding: const EdgeInsets.all(0),
                                onPressed: () {
                                  widget.onChangePicture!();
                                },
                              ),
                            ),
                          ),
                        ),
                      if (widget.onChangePicture != null &&
                          widget.onRemovePicture != null)
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
                                icon: Icon(Icons.edit,
                                    size: largeLayout ? 26 : 20),
                                padding: const EdgeInsets.all(0),
                                onSelected: (value) {
                                  if (value ==
                                      ChangeCoverPopupMenuValue.change) {
                                    widget.onChangePicture!();
                                  } else if (value ==
                                      ChangeCoverPopupMenuValue.remove) {
                                    widget.onRemovePicture!();
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
                      if (widget.onChangePicture == null) const SizedBox(),
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
                                key: _popupMenuButtonKey,
                                icon: Icon(Icons.more_vert,
                                    size: largeLayout ? 26 : 20),
                                padding: const EdgeInsets.all(0),
                                iconColor:
                                    const Color.fromARGB(255, 248, 248, 248),
                                onSelected: _onPopupMenuItemSelected,
                                itemBuilder: (BuildContext context) =>
                                    _getPopupMenuItems(
                                        context, widget.isFavorite),
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
      ),
    );
  }
}
