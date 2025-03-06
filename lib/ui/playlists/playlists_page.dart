import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/albums_grid_delegate.dart';
import 'package:crossonic/ui/common/playlist_grid_cell.dart';
import 'package:crossonic/ui/playlists/playlists_viewmodel.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({super.key});

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  late final PlaylistsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PlaylistsViewModel(
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
          builder: (context, _) {
            return OrientationBuilder(builder: (context, orientation) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: DropdownMenu<PlaylistsSort>(
                          initialSelection: _viewModel.sort,
                          requestFocusOnTap: false,
                          leadingIcon: Icon(Icons.sort),
                          expandedInsets: orientation == Orientation.portrait
                              ? EdgeInsets.zero
                              : null,
                          enableSearch: false,
                          dropdownMenuEntries: [
                            DropdownMenuEntry(
                              value: PlaylistsSort.updated,
                              label: "Updated",
                            ),
                            DropdownMenuEntry(
                              value: PlaylistsSort.created,
                              label: "Created",
                            ),
                            DropdownMenuEntry(
                              value: PlaylistsSort.alphabetical,
                              label: "Alphabetical",
                            ),
                            DropdownMenuEntry(
                              value: PlaylistsSort.songCount,
                              label: "Song Count",
                            ),
                            DropdownMenuEntry(
                              value: PlaylistsSort.duration,
                              label: "Duration",
                            ),
                            DropdownMenuEntry(
                              value: PlaylistsSort.random,
                              label: "Random",
                            ),
                          ],
                          onSelected: (PlaylistsSort? sort) {
                            if (sort == null) return;
                            _viewModel.sort = sort;
                          },
                        ),
                      ),
                    ),
                  ),
                  if (_viewModel.playlists.isEmpty)
                    SliverToBoxAdapter(child: Text("No playlists available")),
                  SliverGrid(
                    gridDelegate: AlbumsGridDelegate(),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= _viewModel.playlists.length) {
                          return null;
                        }
                        final p = _viewModel.playlists[index];
                        return PlaylistGridCell(
                          extraInfo: [
                            "Songs: ${p.songCount}",
                          ],
                          coverId: p.coverId,
                          name: p.name,
                          onTap: () {
                            context.router
                                .push(PlaylistRoute(playlistId: p.id));
                          },
                          onPlay: () async {
                            final result = await _viewModel.play(p);
                            if (!context.mounted) return;
                            toastResult(context, result);
                          },
                          onShuffle: () async {
                            final result =
                                await _viewModel.play(p, shuffle: true);
                            if (!context.mounted) return;
                            toastResult(context, result);
                          },
                          onAddToQueue: (priority) async {
                            final result =
                                await _viewModel.addToQueue(p, priority);
                            if (!context.mounted) return;
                            toastResult(context, result,
                                "Added '${p.name}' to ${priority ? "priority " : ""}queue");
                          },
                          onAddToPlaylist: () {
                            // TODO
                          },
                        );
                      },
                      childCount: _viewModel.playlists.length,
                    ),
                  ),
                ],
              );
            });
          }),
    );
  }
}
