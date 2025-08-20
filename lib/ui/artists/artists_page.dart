import 'package:auto_route/auto_route.dart';
import 'package:crossonic/ui/artists/artists_viewmodel.dart';
import 'package:crossonic/ui/common/albums_grid_delegate.dart';
import 'package:crossonic/ui/common/artist_grid_cell.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class ArtistsPage extends StatefulWidget {
  final String initialSort;

  const ArtistsPage(
      {super.key, @QueryParam("sort") this.initialSort = "alphabetical"});

  @override
  State<ArtistsPage> createState() => _ArtistsPageState();
}

class _ArtistsPageState extends State<ArtistsPage> {
  late final ArtistsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ArtistsViewModel(
      subsonic: context.read(),
      mode: ArtistsPageMode.values.firstWhere(
        (m) => m.name == widget.initialSort,
        orElse: () => ArtistsPageMode.alphabetical,
      ),
    )..load();
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
          builder: (context, _) {
            return OrientationBuilder(builder: (context, orientation) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: DropdownMenu<ArtistsPageMode>(
                          initialSelection: _viewModel.mode,
                          requestFocusOnTap: false,
                          leadingIcon: const Icon(Icons.sort),
                          width:
                              orientation == Orientation.landscape ? 200 : null,
                          expandedInsets: orientation == Orientation.portrait
                              ? EdgeInsets.zero
                              : null,
                          enableSearch: false,
                          dropdownMenuEntries: [
                            const DropdownMenuEntry(
                              value: ArtistsPageMode.alphabetical,
                              label: "Alphabetical",
                            ),
                            const DropdownMenuEntry(
                              value: ArtistsPageMode.favorites,
                              label: "Favorites",
                            ),
                            const DropdownMenuEntry(
                              value: ArtistsPageMode.random,
                              label: "Random",
                            )
                          ],
                          onSelected: (ArtistsPageMode? sortMode) {
                            if (sortMode == null) return;
                            _viewModel.mode = sortMode;
                          },
                        ),
                      ),
                    ),
                  ),
                  if (_viewModel.status == FetchStatus.success &&
                      _viewModel.artists.isEmpty)
                    const SliverToBoxAdapter(
                        child: Text("No artists available")),
                  SliverPadding(
                    padding: const EdgeInsetsGeometry.all(4),
                    sliver: SliverGrid(
                      gridDelegate: AlbumsGridDelegate(),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index > _viewModel.artists.length) {
                            return null;
                          }
                          if (index == _viewModel.artists.length) {
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
                          final a = _viewModel.artists[index];
                          return ArtistGridCell(
                            artist: a,
                            key: ValueKey(a.id),
                          );
                        },
                        childCount:
                            (_viewModel.status == FetchStatus.success ? 0 : 1) +
                                _viewModel.artists.length,
                      ),
                    ),
                  ),
                ],
              );
            });
          }),
    );
  }
}
