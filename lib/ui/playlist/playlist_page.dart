import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/collection_page.dart';
import 'package:crossonic/ui/common/cover_art_decorated.dart';
import 'package:crossonic/ui/common/dialogs/add_to_playlist.dart';
import 'package:crossonic/ui/common/dialogs/chooser.dart';
import 'package:crossonic/ui/common/song_list_item.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:crossonic/ui/playlist/playlist_viewmodel.dart';
import 'package:crossonic/utils/format.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class PlaylistPage extends StatefulWidget {
  final String playlistId;

  const PlaylistPage({super.key, @PathParam("id") required this.playlistId});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  late final PlaylistViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PlaylistViewModel(
      playlistId: widget.playlistId,
      playlistRepository: context.read(),
      audioHandler: context.read(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          if (_viewModel.playlist == null) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          final playlist = _viewModel.playlist!;
          final songs = _viewModel.tracks;
          return CollectionPage(
            name: playlist.name,
            cover: CoverArtDecorated(
              placeholderIcon: Icons.album,
              borderRadius: BorderRadius.circular(10),
              isFavorite: false,
              coverId: playlist.coverId,
              uploading: _viewModel.uploadingCover,
              menuOptions: [
                ContextMenuOption(
                  title: "Play",
                  icon: Icons.play_arrow,
                  onSelected: () {
                    _viewModel.play();
                  },
                ),
                ContextMenuOption(
                  title: "Shuffle",
                  icon: Icons.shuffle,
                  onSelected: () {
                    _viewModel.shuffle();
                  },
                ),
                ContextMenuOption(
                  title: "Add to priority queue",
                  icon: Icons.playlist_play,
                  onSelected: () {
                    _viewModel.addToQueue(true);
                    Toast.show(
                        context, "Added '${playlist.name}' to priority queue");
                  },
                ),
                ContextMenuOption(
                  title: "Add to queue",
                  icon: Icons.playlist_add,
                  onSelected: () {
                    _viewModel.addToQueue(false);
                    Toast.show(context, "Added '${playlist.name}' to queue");
                  },
                ),
                ContextMenuOption(
                  title: "Add to playlist",
                  icon: Icons.playlist_add,
                  onSelected: () {
                    AddToPlaylistDialog.show(
                        context, playlist.name, _viewModel.tracks);
                  },
                ),
                ContextMenuOption(
                  title: _viewModel.reorderEnabled ? "Stop Edit" : "Edit",
                  icon: _viewModel.reorderEnabled ? Icons.edit_off : Icons.edit,
                  onSelected: () {
                    _viewModel.reorderEnabled = !_viewModel.reorderEnabled;
                  },
                ),
                if (_viewModel.changeCoverSupported)
                  ContextMenuOption(
                    title: _viewModel.playlist?.coverId != null
                        ? "Change Cover"
                        : "Set Cover",
                    icon: Icons.image_outlined,
                    onSelected: () async {
                      final result = await _viewModel.changeCover();
                      if (!context.mounted) return;
                      if (result is ImageTooLargeException) {
                        Toast.show(
                            context, "Image too large: max 15 MB allowed");
                      } else {
                        toastResult(context, result);
                      }
                    },
                  ),
                if (_viewModel.changeCoverSupported &&
                    _viewModel.playlist?.coverId != null)
                  ContextMenuOption(
                    title: "Remove Cover",
                    icon: Icons.hide_image_outlined,
                    onSelected: () async {
                      final result = await _viewModel.removeCover();
                      if (!context.mounted) return;
                      toastResult(context, result);
                    },
                  ),
              ],
            ),
            extraInfo: [
              CollectionExtraInfo(
                text: "Created: ${formatDateTime(playlist.created)}",
              ),
              CollectionExtraInfo(
                text: "Updated: ${formatDateTime(playlist.changed)}",
              ),
            ],
            actions: [
              CollectionAction(
                title: "Play",
                icon: Icons.play_arrow,
                onClick: () {
                  _viewModel.play();
                },
              ),
              CollectionAction(
                title: "Shuffle",
                icon: Icons.shuffle,
                onClick: () {
                  _viewModel.shuffle();
                },
              ),
              CollectionAction(
                title: "Prio. Queue",
                icon: Icons.playlist_play,
                onClick: () {
                  _viewModel.addToQueue(true);
                  Toast.show(
                      context, "Added '${playlist.name}' to priority queue");
                },
              ),
              CollectionAction(
                title: "Queue",
                icon: Icons.playlist_add,
                onClick: () {
                  _viewModel.addToQueue(false);
                  Toast.show(context, "Added '${playlist.name}' to queue");
                },
              ),
              CollectionAction(
                title: _viewModel.reorderEnabled ? "Stop Edit" : "Edit",
                icon: _viewModel.reorderEnabled ? Icons.edit_off : Icons.edit,
                onClick: () {
                  _viewModel.reorderEnabled = !_viewModel.reorderEnabled;
                },
              ),
            ],
            contentTitle: "Tracks (${songs.length})",
            reorderableItemCount: songs.length,
            onReorder: (oldIndex, newIndex) async {
              final result = await _viewModel.reorder(oldIndex, newIndex);
              if (!context.mounted) return;
              toastResult(context, result);
            },
            reorderableItemBuilder: (context, index) {
              final s = songs[index];
              return SongListItem(
                key: ValueKey(index),
                id: s.id,
                title: s.title,
                reorderIndex: _viewModel.reorderEnabled ? index : null,
                artist: s.displayArtist,
                duration: s.duration,
                coverId: s.coverId,
                year: s.year,
                onAddToPlaylist: () {
                  AddToPlaylistDialog.show(context, s.title, [s]);
                },
                onAddToQueue: (priority) {
                  _viewModel.addSongToQueue(s, priority);
                  Toast.show(context,
                      "Added '${s.title}' to ${priority ? "priority " : ""}queue");
                },
                onGoToAlbum: s.album != null
                    ? () {
                        context.router.push(AlbumRoute(albumId: s.album!.id));
                      }
                    : null,
                onGoToArtist: s.artists.isNotEmpty
                    ? () async {
                        final router = context.router;
                        final artistId = await ChooserDialog.chooseArtist(
                            context, s.artists.toList());
                        if (artistId == null) return;
                        router.push(ArtistRoute(artistId: artistId));
                      }
                    : null,
                onRemove: () async {
                  final result = await _viewModel.remove(index);
                  if (!context.mounted) return;
                  toastResult(context, result);
                },
                onTap: (ctrlPressed) {
                  _viewModel.play(index, ctrlPressed);
                },
              );
            },
          );
        },
      ),
    );
  }
}
