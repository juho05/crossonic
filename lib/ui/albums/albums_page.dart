import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/albums/albums_viewmodel.dart';
import 'package:crossonic/ui/common/album_grid_cell.dart';
import 'package:crossonic/ui/common/albums_grid_delegate.dart';
import 'package:crossonic/ui/common/dialogs/add_to_playlist.dart';
import 'package:crossonic/ui/common/dialogs/chooser.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class AlbumsPage extends StatefulWidget {
  final String mode;
  final String? genre;

  const AlbumsPage({
    super.key,
    @QueryParam("mode") this.mode = "alphabetical",
    @QueryParam("genre") this.genre,
  });

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  late final AlbumsViewModel _viewModel;

  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.genre != null) {
      _viewModel = AlbumsViewModel.genre(
        audioHandler: context.read(),
        subsonic: context.read(),
        genre: widget.genre!,
      );
    } else {
      _viewModel = AlbumsViewModel(
        audioHandler: context.read(),
        subsonic: context.read(),
        mode: AlbumsPageMode.values.firstWhere(
          (m) => m.name == widget.mode,
          orElse: () => AlbumsPageMode.alphabetical,
        ),
      );
    }
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return OrientationBuilder(builder: (context, orientation) {
              return CustomScrollView(
                controller: _controller,
                slivers: [
                  SliverToBoxAdapter(
                    child: _viewModel.mode != AlbumsPageMode.genre
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: DropdownMenu<AlbumsPageMode>(
                                initialSelection: _viewModel.mode,
                                requestFocusOnTap: false,
                                leadingIcon: const Icon(Icons.sort),
                                expandedInsets:
                                    orientation == Orientation.portrait
                                        ? EdgeInsets.zero
                                        : null,
                                enableSearch: false,
                                dropdownMenuEntries: [
                                  const DropdownMenuEntry(
                                    value: AlbumsPageMode.alphabetical,
                                    label: "Alphabetical",
                                  ),
                                  const DropdownMenuEntry(
                                    value: AlbumsPageMode.favorites,
                                    label: "Favorites",
                                  ),
                                  const DropdownMenuEntry(
                                    value: AlbumsPageMode.random,
                                    label: "Random",
                                  ),
                                  const DropdownMenuEntry(
                                    value: AlbumsPageMode.recentlyAdded,
                                    label: "Recently added",
                                  ),
                                  const DropdownMenuEntry(
                                    value: AlbumsPageMode.recentlyPlayed,
                                    label: "Recently played",
                                  ),
                                  const DropdownMenuEntry(
                                    value: AlbumsPageMode.frequentlyPlayed,
                                    label: "Frequently played",
                                  ),
                                ],
                                onSelected: (AlbumsPageMode? mode) {
                                  if (mode == null) return;
                                  _viewModel.mode = mode;
                                },
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Text(
                              "Genre: ${widget.genre}",
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge!
                                  .copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                            ),
                          ),
                  ),
                  if (_viewModel.status == FetchStatus.success &&
                      _viewModel.albums.isEmpty)
                    const SliverToBoxAdapter(child: Text("No albums available")),
                  SliverGrid(
                    gridDelegate: AlbumsGridDelegate(),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index > _viewModel.albums.length) {
                          return null;
                        }
                        if (index == _viewModel.albums.length) {
                          return switch (_viewModel.status) {
                            FetchStatus.success => null,
                            FetchStatus.failure => const Center(
                                child: Icon(Icons.wifi_off),
                              ),
                            _ => const Center(
                                child: CircularProgressIndicator.adaptive(),
                              ),
                          };
                        }
                        final a = _viewModel.albums[index];
                        return AlbumGridCell(
                          id: a.id,
                          extraInfo: [
                            a.displayArtist,
                            a.year?.toString() ?? "Unknown year",
                          ],
                          coverId: a.coverId,
                          name: a.name,
                          onTap: () {
                            context.router.push(AlbumRoute(albumId: a.id));
                          },
                          onPlay: () async {
                            final result = await _viewModel.play(a);
                            if (!context.mounted) return;
                            toastResult(context, result);
                          },
                          onShuffle: () async {
                            final result =
                                await _viewModel.play(a, shuffle: true);
                            if (!context.mounted) return;
                            toastResult(context, result);
                          },
                          onAddToQueue: (priority) async {
                            final result =
                                await _viewModel.addToQueue(a, priority);
                            if (!context.mounted) return;
                            toastResult(context, result,
                                successMsg:
                                    "Added '${a.name}' to ${priority ? "priority " : ""}queue");
                          },
                          onGoToArtist: a.artists.isNotEmpty
                              ? () async {
                                  final artistId =
                                      await ChooserDialog.chooseArtist(
                                          context, a.artists.toList());
                                  if (artistId == null || !context.mounted) {
                                    return;
                                  }
                                  context.router
                                      .push(ArtistRoute(artistId: artistId));
                                }
                              : null,
                          onAddToPlaylist: () async {
                            final result = await _viewModel.getAlbumSongs(a);
                            if (!context.mounted) return;
                            switch (result) {
                              case Err():
                                toastResult(context, result);
                              case Ok():
                                AddToPlaylistDialog.show(
                                    context, a.name, result.value);
                            }
                          },
                        );
                      },
                      childCount:
                          (_viewModel.status == FetchStatus.success ? 0 : 1) +
                              _viewModel.albums.length,
                    ),
                  ),
                ],
              );
            });
          }),
    );
  }

  void _onScroll() {
    if (_isBottom) _viewModel.nextPage();
  }

  bool get _isBottom {
    if (!_controller.hasClients) return false;
    final maxScroll = _controller.position.maxScrollExtent;
    final currentScroll = _controller.offset;
    return currentScroll >= (maxScroll * 0.8);
  }
}
