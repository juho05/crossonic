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
            ],
            contentTitle: "Tracks (${songs.length})",
            content: Column(
                children: List<Widget>.generate(songs.length, (index) {
              final s = songs[index];
              return SongListItem(
                id: s.id,
                title: s.title,
                artist: s.displayArtist,
                duration: s.duration,
                coverId: s.coverId,
                onAddToPlaylist: () {
                  AddToPlaylistDialog.show(context, s.title, [s]);
                },
                onAddToQueue: (priority) {
                  _viewModel.addSongToQueue(s, priority);
                  Toast.show(context,
                      "Added '${s.title}' to ${priority ? "priority " : ""}queue");
                },
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
                onTap: () {
                  _viewModel.play(index);
                },
              );
            })),
          );
        },
      ),
    );
  }
}
