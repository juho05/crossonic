import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/album/album_viewmodel.dart';
import 'package:crossonic/ui/common/collection_page.dart';
import 'package:crossonic/ui/common/cover_art_decorated.dart';
import 'package:crossonic/ui/common/dialogs/add_to_playlist.dart';
import 'package:crossonic/ui/common/dialogs/chooser.dart';
import 'package:crossonic/ui/common/song_list_item.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class AlbumPage extends StatefulWidget {
  final String albumId;

  const AlbumPage({super.key, @PathParam("id") required this.albumId});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  late final AlbumViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AlbumViewModel(
      subsonicRepository: context.read(),
      favoritesRepository: context.read(),
      audioHandler: context.read(),
    )..load(widget.albumId);
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
          final album = _viewModel.album!;
          final songs = _viewModel.album!.songs ?? [];
          final showDiscs = songs.isNotEmpty &&
              ((songs.last.discNr ?? 1) > 1 || album.discTitles.isNotEmpty);
          return CollectionPage(
            name: album.name,
            loadingDescription: _viewModel.description == null,
            description: (_viewModel.description ?? "").isNotEmpty
                ? _viewModel.description
                : null,
            cover: CoverArtDecorated(
              placeholderIcon: Icons.album,
              borderRadius: BorderRadius.circular(10),
              isFavorite: _viewModel.favorite,
              coverId: album.coverId,
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
                        context, "Added '${album.name}' to priority queue");
                  },
                ),
                ContextMenuOption(
                  title: "Add to queue",
                  icon: Icons.playlist_add,
                  onSelected: () {
                    _viewModel.addToQueue(false);
                    Toast.show(context, "Added '${album.name}' to queue");
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
                  onSelected: () {
                    AddToPlaylistDialog.show(context, album.name, songs);
                  },
                ),
                ContextMenuOption(
                  title: "Go to artist",
                  icon: Icons.person,
                  onSelected: () async {
                    final router = context.router;
                    final artistId = await ChooserDialog.chooseArtist(
                        context, album.artists.toList());
                    if (artistId == null) return;
                    router.push(ArtistRoute(artistId: artistId));
                  },
                ),
              ],
            ),
            extraInfo: [
              CollectionExtraInfo(
                text: album.displayArtist +
                    (album.year != null ? ' • ${album.year}' : ''),
                onClick: () async {
                  final router = context.router;
                  final artistId = await ChooserDialog.chooseArtist(
                      context, album.artists.toList());
                  if (artistId == null) return;
                  router.push(ArtistRoute(artistId: artistId));
                },
              ),
            ],
            actions: [
              CollectionAction(
                title: "Play",
                icon: Icons.play_arrow,
                highlighted: true,
                onClick: () {
                  _viewModel.play();
                },
              ),
              CollectionAction(
                title: "Prio. Queue",
                icon: Icons.playlist_play,
                onClick: () {
                  _viewModel.addToQueue(true);
                  Toast.show(
                      context, "Added '${album.name}' to priority queue");
                },
              ),
              CollectionAction(
                title: "Queue",
                icon: Icons.playlist_add,
                onClick: () {
                  _viewModel.addToQueue(false);
                  Toast.show(context, "Added '${album.name}' to queue");
                },
              ),
            ],
            contentTitle: "Tracks (${songs.length})",
            content: Column(
                children: List<Widget>.generate(songs.length, (index) {
              final s = songs[index];
              final listItem = SongListItem(
                id: s.id,
                title: s.title,
                artist: s.displayArtist,
                duration: s.duration,
                trackNr: s.trackNr ?? index,
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
                onTap: (ctrlPressed) {
                  _viewModel.play(index, ctrlPressed);
                },
              );
              if (showDiscs &&
                  songs[index].discNr != null &&
                  (index == 0 ||
                      songs[index].discNr != songs[index - 1].discNr)) {
                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: index == 0 ? 8 : 0),
                      child: WithContextMenu(
                        openOnTap: true,
                        options: [
                          ContextMenuOption(
                            title: "Play",
                            icon: Icons.play_arrow,
                            onSelected: () =>
                                _viewModel.playDisc(songs[index].discNr!),
                          ),
                          ContextMenuOption(
                            title: "Shuffle",
                            icon: Icons.shuffle,
                            onSelected: () => _viewModel
                                .playDisc(songs[index].discNr!, shuffle: true),
                          ),
                          ContextMenuOption(
                            title: "Add to priority queue",
                            icon: Icons.playlist_play,
                            onSelected: () {
                              _viewModel.addDiscToQueue(
                                  songs[index].discNr!, true);
                              Toast.show(context,
                                  "Added '${album.discTitles[songs[index].discNr!] ?? "Disc ${songs[index].discNr}"}' to priority queue");
                            },
                          ),
                          ContextMenuOption(
                            title: "Add to queue",
                            icon: Icons.playlist_add,
                            onSelected: () {
                              _viewModel.addDiscToQueue(
                                  songs[index].discNr!, false);
                              Toast.show(context,
                                  "Added '${album.discTitles[songs[index].discNr!] ?? "Disc ${songs[index].discNr}"}' to queue");
                            },
                          ),
                        ],
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.album),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OrientationBuilder(
                                  builder: (context, orientation) => Text(
                                    album.discTitles[songs[index].discNr!] ??
                                        "Disc ${songs[index].discNr}",
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium!
                                        .copyWith(
                                          fontWeight: orientation ==
                                                  Orientation.portrait
                                              ? FontWeight.w800
                                              : FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.album),
                            ],
                          ),
                        ),
                      ),
                    ),
                    listItem,
                  ],
                );
              }
              return listItem;
            })),
          );
        },
      ),
    );
  }
}
