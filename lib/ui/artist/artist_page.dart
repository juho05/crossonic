import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/ui/artist/artist_viewmodel.dart';
import 'package:crossonic/ui/common/album_grid_cell.dart';
import 'package:crossonic/ui/common/albums_grid_delegate.dart';
import 'package:crossonic/ui/common/collection_page.dart';
import 'package:crossonic/ui/common/cover_art_decorated.dart';
import 'package:crossonic/ui/common/dialogs/add_to_playlist.dart';
import 'package:crossonic/ui/common/dialogs/chooser.dart';
import 'package:crossonic/ui/common/dialogs/media_info.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:crossonic/utils/fetch_status.dart';
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
                        context, "Shuffle", ["Releases", "Songs"]);
                    if (option == null) return;
                    _viewModel.play(
                        shuffleReleases: option == 0,
                        shuffleSongs: option == 1);
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
                    toastResult(context, result,
                        successMsg: "Added '${artist.name} to queue");
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
                    AddToPlaylistDialog.show(context, artist.name,
                        () => _viewModel.getArtistSongs(artist));
                  },
                ),
                ContextMenuOption(
                  title: "Info",
                  icon: Icons.info_outline,
                  onSelected: () {
                    MediaInfoDialog.showArtist(context, artist.id);
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
                      context, "Shuffle", ["Releases", "Songs"]);
                  if (option == null) return;
                  final result = await _viewModel.play(
                      shuffleReleases: option == 0, shuffleSongs: option == 1);
                  if (!context.mounted) return;
                  toastResult(context, result);
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
                  toastResult(context, result,
                      successMsg: "Added '${artist.name}' to queue");
                },
              ),
            ],
            contentSliver: SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              sliver: SliverMainAxisGroup(
                slivers: () {
                  final slivers = <Widget>[];
                  final currentAlbums = <Album>[];

                  Widget createSliverGrid([List<Album>? gridAlbums]) {
                    gridAlbums ??= List.of(currentAlbums);
                    return SliverGrid.builder(
                      gridDelegate: AlbumsGridDelegate(),
                      itemCount: gridAlbums.length,
                      itemBuilder: (context, i) => AlbumGridCell(
                        album: gridAlbums![i],
                      ),
                    );
                  }

                  Widget createCategoryDivider({
                    required bool isFirstReleaseType,
                    ReleaseType releaseType = ReleaseType.album,
                    bool isAppearsOn = false,
                  }) {
                    return SliverPadding(
                      padding: EdgeInsets.only(
                          top: isAppearsOn ? 0 : (isFirstReleaseType ? 4 : 12)),
                      sliver: SliverToBoxAdapter(
                        child: WithContextMenu(
                          openOnTap: true,
                          enabled: albums.isNotEmpty &&
                              (_viewModel.appearsOn.isNotEmpty ||
                                  albums.first.releaseType !=
                                      albums.last.releaseType),
                          options: [
                            ContextMenuOption(
                                title: "Play",
                                icon: Icons.play_arrow,
                                onSelected: () {
                                  if (isAppearsOn) {
                                    _viewModel.playAppearsOn();
                                  } else {
                                    _viewModel.playReleases(releaseType);
                                  }
                                }),
                            ContextMenuOption(
                              title: "Shuffle",
                              icon: Icons.shuffle,
                              onSelected: () async {
                                final option = await ChooserDialog.choose(
                                    context, "Shuffle", [
                                  isAppearsOn
                                      ? "Appears on"
                                      : ArtistViewModel
                                          .releaseTypeTitles[releaseType]!,
                                  "Songs"
                                ]);
                                if (option == null) return;
                                if (isAppearsOn) {
                                  _viewModel.playAppearsOn(
                                      shuffleReleases: option == 0,
                                      shuffleSongs: option == 1);
                                } else {
                                  _viewModel.playReleases(releaseType,
                                      shuffleReleases: option == 0,
                                      shuffleSongs: option == 1);
                                }
                              },
                            ),
                            ContextMenuOption(
                              title: "Add to priority queue",
                              icon: Icons.playlist_play,
                              onSelected: () {
                                if (isAppearsOn) {
                                  _viewModel.addAppearsOnToQueue(true);
                                  Toast.show(context,
                                      "Added 'Appears on' to priority queue");
                                } else {
                                  _viewModel.addReleasesToQueue(
                                      releaseType, true);
                                  Toast.show(context,
                                      "Added '${ArtistViewModel.releaseTypeTitles[releaseType]}' to priority queue");
                                }
                              },
                            ),
                            ContextMenuOption(
                              title: "Add to queue",
                              icon: Icons.playlist_add,
                              onSelected: () {
                                if (isAppearsOn) {
                                  _viewModel.addAppearsOnToQueue(false);
                                  Toast.show(
                                      context, "Added 'Appears on' to queue");
                                } else {
                                  _viewModel.addReleasesToQueue(
                                      releaseType, false);
                                  Toast.show(context,
                                      "Added '${ArtistViewModel.releaseTypeTitles[releaseType]}' to queue");
                                }
                              },
                            ),
                          ],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OrientationBuilder(
                                    builder: (context, orientation) => Text(
                                      isAppearsOn
                                          ? "Appears on"
                                          : ArtistViewModel
                                              .releaseTypeTitles[releaseType]!,
                                      textAlign: TextAlign.left,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  ReleaseType? lastReleaseType;
                  for (final album in albums) {
                    if (album.releaseType != lastReleaseType) {
                      if (currentAlbums.isNotEmpty) {
                        slivers.add(createSliverGrid());
                        currentAlbums.clear();
                      }
                      slivers.add(createCategoryDivider(
                        isFirstReleaseType: lastReleaseType == null,
                        releaseType: album.releaseType,
                      ));
                      lastReleaseType = album.releaseType;
                    }
                    currentAlbums.add(album);
                  }
                  if (currentAlbums.isNotEmpty) {
                    slivers.add(createSliverGrid());
                    currentAlbums.clear();
                  }

                  if (_viewModel.appearsOn.isNotEmpty) {
                    if (albums.isNotEmpty) {
                      slivers.add(const SliverToBoxAdapter(
                        child: Divider(),
                      ));
                    }
                    slivers.add(createCategoryDivider(
                      isFirstReleaseType: albums.isEmpty,
                      isAppearsOn: true,
                    ));
                    slivers.add(createSliverGrid(_viewModel.appearsOn));
                  }

                  return slivers;
                }(),
              ),
            ),
          );
        },
      ),
    );
  }
}
