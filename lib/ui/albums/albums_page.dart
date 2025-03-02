import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/albums/albums_viewmodel.dart';
import 'package:crossonic/ui/common/album_grid_cell.dart';
import 'package:crossonic/ui/common/albums_grid_delegate.dart';
import 'package:crossonic/ui/common/dialogs/chooser.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class AlbumsPage extends StatefulWidget {
  final String initialSort;

  const AlbumsPage(
      {super.key, @QueryParam("sort") this.initialSort = "alphabetical"});

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  late final AlbumsViewModel _viewModel;

  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel = AlbumsViewModel(
      audioHandler: context.read(),
      subsonic: context.read(),
      mode: AlbumsSortMode.values.firstWhere(
        (m) => m.name == widget.initialSort,
        orElse: () => AlbumsSortMode.alphabetical,
      ),
    )..nextPage();
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
            return CustomScrollView(
              controller: _controller,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: DropdownButton<AlbumsSortMode>(
                        value: _viewModel.mode,
                        items: [
                          DropdownMenuItem(
                            value: AlbumsSortMode.alphabetical,
                            child: Text("Alphabetical"),
                          ),
                          DropdownMenuItem(
                            value: AlbumsSortMode.starred,
                            child: Text("Favorites"),
                          ),
                          DropdownMenuItem(
                            value: AlbumsSortMode.random,
                            child: Text("Random"),
                          ),
                          DropdownMenuItem(
                            value: AlbumsSortMode.recentlyAdded,
                            child: Text("Recently added"),
                          ),
                          DropdownMenuItem(
                            value: AlbumsSortMode.recentlyPlayed,
                            child: Text("Recently played"),
                          ),
                          DropdownMenuItem(
                            value: AlbumsSortMode.frequentlyPlayed,
                            child: Text("Frequently played"),
                          ),
                        ],
                        onChanged: (AlbumsSortMode? sortMode) {
                          if (sortMode == null) return;
                          _viewModel.mode = sortMode;
                        },
                      ),
                    ),
                  ),
                ),
                if (_viewModel.status == FetchStatus.success &&
                    _viewModel.albums.isEmpty)
                  Text("No albums available"),
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
                              "Added '${a.name}' to ${priority ? "priority " : ""}queue");
                        },
                        onGoToArtist: () async {
                          final artistId = await ChooserDialog.chooseArtist(
                              context, a.artists.toList());
                          if (artistId == null || !context.mounted) return;
                          context.router.push(ArtistRoute(artistId: artistId));
                        },
                        onAddToPlaylist: () {
                          // TODO
                        },
                      );
                    },
                  ),
                ),
              ],
            );
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
