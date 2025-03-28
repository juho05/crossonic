import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/artist/artist_viewmodel.dart';
import 'package:crossonic/ui/common/album_grid_cell.dart';
import 'package:crossonic/ui/common/albums_grid_delegate.dart';
import 'package:crossonic/ui/common/collection_page.dart';
import 'package:crossonic/ui/common/cover_art_decorated.dart';
import 'package:crossonic/ui/common/dialogs/add_to_playlist.dart';
import 'package:crossonic/ui/common/dialogs/chooser.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class ArtistPage extends StatefulWidget {
  final String artistId;
  const ArtistPage({super.key, @PathParam("id") required this.artistId});

  @override
  State<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage> {
  late final ArtistViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ArtistViewModel(
      subsonicRepository: context.read(),
      favoritesRepository: context.read(),
      audioHandler: context.read(),
    )..load(widget.artistId);
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
          switch (_viewModel.status) {
            case FetchStatus.initial || FetchStatus.loading:
              return const Center(child: CircularProgressIndicator.adaptive());
            case FetchStatus.failure:
              return const Center(child: Icon(Icons.wifi_off));
            case FetchStatus.success:
          }
          final artist = _viewModel.artist!;
          final albums = _viewModel.artist!.albums ?? [];
          return CollectionPage(
            name: artist.name,
            loadingDescription: _viewModel.description == null,
            description: (_viewModel.description ?? "").isNotEmpty
                ? _viewModel.description
                : null,
            cover: CoverArtDecorated(
              placeholderIcon: Icons.person,
              borderRadius: BorderRadius.circular(10),
              isFavorite: _viewModel.favorite,
              coverId: artist.coverId,
              menuOptions: [
                ContextMenuOption(
                  title: "Play",
                  icon: Icons.play_arrow,
                  onSelected: () async {
                    final result = await _viewModel.play();
                    if (!context.mounted) return;
                    toastResult(context, result);
                  },
                ),
                ContextMenuOption(
                  title: "Shuffle",
                  icon: Icons.shuffle,
                  onSelected: () async {
                    final option = await ChooserDialog.choose(
                        context, "Shuffle", ["Albums", "Songs"]);
                    if (option == null) return;
                    _viewModel.play(
                        shuffleAlbums: option == 0, shuffleSongs: option == 1);
                  },
                ),
                ContextMenuOption(
                  title: "Add to priority queue",
                  icon: Icons.playlist_play,
                  onSelected: () async {
                    final result = await _viewModel.addToQueue(true);
                    if (!context.mounted) return;
                    toastResult(context, result,
                        successMsg: "Added '${artist.name} to priority queue");
                  },
                ),
                ContextMenuOption(
                  title: "Add to queue",
                  icon: Icons.playlist_add,
                  onSelected: () async {
                    final result = await _viewModel.addToQueue(false);
                    if (!context.mounted) return;
                    toastResult(
                        context, result, successMsg: "Added '${artist.name} to queue");
                  },
                ),
                ContextMenuOption(
                  title: _viewModel.favorite
                      ? "Remove from favorites"
                      : "Add to favorites",
                  icon:
                      _viewModel.favorite ? Icons.heart_broken : Icons.favorite,
                  onSelected: () async {
                    final result = await _viewModel.toggleFavorite();
                    if (!context.mounted) return;
                    toastResult(context, result);
                  },
                ),
                ContextMenuOption(
                  title: "Add to playlist",
                  icon: Icons.playlist_add,
                  onSelected: () async {
                    final result = await _viewModel.getArtistSongs(artist);
                    if (!context.mounted) return;
                    switch (result) {
                      case Err():
                        toastResult(context, result);
                      case Ok():
                        AddToPlaylistDialog.show(
                            context, artist.name, result.value);
                    }
                  },
                ),
              ],
            ),
            extraInfo: [
              CollectionExtraInfo(
                text: (artist.genres ?? []).isNotEmpty
                    ? artist.genres!
                        .sublist(0, min(3, artist.genres!.length))
                        .join(", ")
                    : "Unknown genre",
              ),
            ],
            actions: [
              CollectionAction(
                title: "Shuffle",
                icon: Icons.shuffle,
                highlighted: true,
                onClick: () async {
                  final option = await ChooserDialog.choose(
                      context, "Shuffle", ["Albums", "Songs"]);
                  if (option == null) return;
                  _viewModel.play(
                      shuffleAlbums: option == 0, shuffleSongs: option == 1);
                },
              ),
              CollectionAction(
                title: "Play",
                icon: Icons.play_arrow,
                onClick: () async {
                  final result = await _viewModel.play();
                  if (!context.mounted) return;
                  toastResult(context, result);
                },
              ),
              CollectionAction(
                title: "Prio. Queue",
                icon: Icons.playlist_play,
                onClick: () async {
                  final result = await _viewModel.addToQueue(true);
                  if (!context.mounted) return;
                  toastResult(context, result,
                      successMsg: "Added '${artist.name}' priority to queue");
                },
              ),
              CollectionAction(
                title: "Queue",
                icon: Icons.playlist_add,
                onClick: () async {
                  final result = await _viewModel.addToQueue(false);
                  if (!context.mounted) return;
                  toastResult(
                      context, result, successMsg: "Added '${artist.name}' to queue");
                },
              ),
            ],
            contentTitle: "Albums (${albums.length})",
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: AlbumsGridDelegate(),
                itemCount: albums.length,
                itemBuilder: (context, i) => AlbumGridCell(
                  id: albums[i].id,
                  name: albums[i].name,
                  coverId: albums[i].coverId,
                  extraInfo: [
                    albums[i].year != null
                        ? "${albums[i].year}"
                        : "Unknown year"
                  ],
                  onTap: () {
                    context.router.push(AlbumRoute(albumId: albums[i].id));
                  },
                  onPlay: () async {
                    final result = await _viewModel.playAlbum(albums[i]);
                    if (!context.mounted) return;
                    toastResult(context, result);
                  },
                  onShuffle: () async {
                    final result =
                        await _viewModel.playAlbum(albums[i], shuffle: true);
                    if (!context.mounted) return;
                    toastResult(context, result);
                  },
                  onAddToQueue: (priority) async {
                    final result =
                        await _viewModel.addAlbumToQueue(albums[i], priority);
                    if (!context.mounted) return;
                    toastResult(context, result,
                        successMsg: "Added '${albums[i].name}' to ${priority ? " priority" : ""} queue");
                  },
                  onAddToPlaylist: () async {
                    final result = await _viewModel.getAlbumSongs(albums[i]);
                    if (!context.mounted) return;
                    switch (result) {
                      case Err():
                        toastResult(context, result);
                      case Ok():
                        AddToPlaylistDialog.show(
                            context, albums[i].name, result.value);
                    }
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
