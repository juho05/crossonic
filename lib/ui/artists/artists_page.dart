import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/artists/artists_viewmodel.dart';
import 'package:crossonic/ui/common/albums_grid_delegate.dart';
import 'package:crossonic/ui/common/artist_grid_cell.dart';
import 'package:crossonic/ui/common/dialogs/add_to_playlist.dart';
import 'package:crossonic/ui/common/dialogs/chooser.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:crossonic/utils/result_toast.dart';
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
      audioHandler: context.read(),
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
                            id: a.id,
                            key: ValueKey(a.id),
                            extraInfo: [
                              if (a.albumCount != null)
                                "Releases: ${a.albumCount}"
                            ],
                            coverId: a.coverId,
                            name: a.name,
                            onTap: () {
                              context.router.push(ArtistRoute(artistId: a.id));
                            },
                            onPlay: () async {
                              final result = await _viewModel.play(a);
                              if (!context.mounted) return;
                              toastResult(context, result);
                            },
                            onShuffle: () async {
                              final option = await ChooserDialog.choose(
                                  context, "Shuffle", ["Releases", "Songs"]);
                              if (option == null) return;
                              final result = await _viewModel.play(a,
                                  shuffleAlbums: option == 0,
                                  shuffleSongs: option == 1);
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
                            onAddToPlaylist: () async {
                              final result = await _viewModel.getArtistSongs(a);
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
