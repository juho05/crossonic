import 'package:auto_route/auto_route.dart';
import 'package:crossonic/ui/albums/albums_viewmodel.dart';
import 'package:crossonic/ui/common/album_grid_cell.dart';
import 'package:crossonic/ui/common/albums_grid_delegate.dart';
import 'package:crossonic/utils/fetch_status.dart';
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
        subsonic: context.read(),
        genre: widget.genre!,
      );
    } else {
      _viewModel = AlbumsViewModel(
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
                                width: orientation == Orientation.landscape
                                    ? 240
                                    : null,
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
                              horizontal: 8,
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
                    const SliverToBoxAdapter(
                        child: Text("No releases available")),
                  SliverPadding(
                    padding: const EdgeInsetsGeometry.symmetric(horizontal: 4),
                    sliver: SliverGrid(
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
                            album: a,
                          );
                        },
                        childCount:
                            (_viewModel.status == FetchStatus.success ? 0 : 1) +
                                _viewModel.albums.length,
                      ),
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
