import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/album/album_viewmodel.dart';
import 'package:crossonic/ui/common/clickable_list_item.dart';
import 'package:crossonic/ui/common/collection_page.dart';
import 'package:crossonic/ui/common/cover_art_decorated.dart';
import 'package:crossonic/ui/common/dialogs/add_to_playlist.dart';
import 'package:crossonic/ui/common/dialogs/chooser.dart';
import 'package:crossonic/ui/common/dialogs/media_info.dart';
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

  static final double discTitleExtent = 40;

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

          final maxTrackDigitCount = (_viewModel.listItems.map((e) {
                    if (e.$1 != null) {
                      return 0;
                    }
                    return e.$2!.$1.trackNr ?? e.$2!.$2;
                  }).maxOrNull ??
                  1)
              .toString()
              .length;

          return CollectionPage(
            name: _viewModel.name,
            loadingDescription: _viewModel.description == null,
            description: (_viewModel.description ?? "").isNotEmpty
                ? _viewModel.description
                : null,
            cover: CoverArtDecorated(
              placeholderIcon: Icons.album,
              borderRadius: BorderRadius.circular(10),
              isFavorite: _viewModel.favorite,
              coverId: _viewModel.coverId,
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
                    Toast.show(context,
                        "Added '${_viewModel.name}' to priority queue");
                  },
                ),
                ContextMenuOption(
                  title: "Add to queue",
                  icon: Icons.playlist_add,
                  onSelected: () {
                    _viewModel.addToQueue(false);
                    Toast.show(context, "Added '${_viewModel.name}' to queue");
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
                    AddToPlaylistDialog.show(
                        context, _viewModel.name, _viewModel.songs);
                  },
                ),
                ContextMenuOption(
                  title: "Go to artist",
                  icon: Icons.person,
                  onSelected: () async {
                    final router = context.router;
                    final artistId = await ChooserDialog.chooseArtist(
                        context, _viewModel.artists);
                    if (artistId == null) return;
                    router.push(ArtistRoute(artistId: artistId));
                  },
                ),
                ContextMenuOption(
                  title: "Info",
                  icon: Icons.info_outline,
                  onSelected: () {
                    MediaInfoDialog.showAlbum(context, _viewModel.id);
                  },
                )
              ],
            ),
            extraInfo: [
              CollectionExtraInfo(
                text: _viewModel.displayArtist +
                    (_viewModel.year != null ? ' • ${_viewModel.year}' : ''),
                onClick: () async {
                  final router = context.router;
                  final artistId = await ChooserDialog.chooseArtist(
                      context, _viewModel.artists);
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
                      context, "Added '${_viewModel.name}' to priority queue");
                },
              ),
              CollectionAction(
                title: "Queue",
                icon: Icons.playlist_add,
                onClick: () {
                  _viewModel.addToQueue(false);
                  Toast.show(context, "Added '${_viewModel.name}' to queue");
                },
              ),
            ],
            contentTitle: "Tracks (${_viewModel.songs.length})",
            contentSliver: SliverVariedExtentList.builder(
              itemCount: _viewModel.listItems.length,
              itemBuilder: (context, index) {
                if (index >= _viewModel.listItems.length) return null;
                if (_viewModel.listItems[index].$1 != null) {
                  final discNr = _viewModel.listItems[index].$1!;
                  return Padding(
                    padding: EdgeInsets.only(top: index == 0 ? 8 : 0),
                    child: WithContextMenu(
                      openOnTap: true,
                      options: [
                        ContextMenuOption(
                          title: "Play",
                          icon: Icons.play_arrow,
                          onSelected: () => _viewModel.playDisc(discNr),
                        ),
                        ContextMenuOption(
                          title: "Shuffle",
                          icon: Icons.shuffle,
                          onSelected: () =>
                              _viewModel.playDisc(discNr, shuffle: true),
                        ),
                        ContextMenuOption(
                          title: "Add to priority queue",
                          icon: Icons.playlist_play,
                          onSelected: () {
                            _viewModel.addDiscToQueue(discNr, true);
                            Toast.show(context,
                                "Added '${_viewModel.discTitles[discNr] ?? "Disc $discNr"}' to priority queue");
                          },
                        ),
                        ContextMenuOption(
                          title: "Add to queue",
                          icon: Icons.playlist_add,
                          onSelected: () {
                            _viewModel.addDiscToQueue(discNr, false);
                            Toast.show(context,
                                "Added '${_viewModel.discTitles[discNr] ?? "Disc $discNr"}' to queue");
                          },
                        ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.album),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OrientationBuilder(
                                builder: (context, orientation) => Text(
                                  _viewModel.discTitles[discNr] ??
                                      "Disc $discNr",
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium!
                                      .copyWith(
                                        fontWeight:
                                            orientation == Orientation.portrait
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
                  );
                }
                final s = _viewModel.listItems[index].$2!.$1;
                final songIndex = _viewModel.listItems[index].$2!.$2;
                return SongListItem(
                  song: s,
                  disableGoToAlbum: true,
                  showTrackNr: true,
                  fallbackTrackNr: songIndex + 1,
                  trackDigits: maxTrackDigitCount,
                  showYear: false,
                  onTap: (ctrlPressed) {
                    _viewModel.play(songIndex, ctrlPressed);
                  },
                );
              },
              itemExtentBuilder: (index, dimensions) {
                if (index >= _viewModel.listItems.length) return null;
                if (_viewModel.listItems[index].$1 != null) {
                  return discTitleExtent + (index == 0 ? 8 : 0);
                }
                return ClickableListItem.verticalExtent;
              },
            ),
          );
        },
      ),
    );
  }
}
