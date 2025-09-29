import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/albums_grid_delegate.dart';
import 'package:crossonic/ui/common/buttons.dart';
import 'package:crossonic/ui/common/dialogs/add_to_playlist.dart';
import 'package:crossonic/ui/common/dialogs/confirmation.dart';
import 'package:crossonic/ui/common/playlist_grid_cell.dart';
import 'package:crossonic/ui/common/search_input.dart';
import 'package:crossonic/ui/main/layout_mode.dart';
import 'package:crossonic/ui/playlists/playlists_viewmodel.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/foundation.dart';
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
      songDownloader: context.read(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool? wasDesktop;
    return LayoutModeBuilder(builder: (context, isDesktop) {
      if (wasDesktop != null && wasDesktop != isDesktop) {
        if (_viewModel.searchTerm.isNotEmpty || _viewModel.offline) {
          _viewModel.showFilters = true;
        }
      }
      wasDesktop = isDesktop;
      return Scaffold(
        floatingActionButton: !isDesktop
            ? FloatingActionButton(
                onPressed: () {
                  context.router.push(CreatePlaylistRoute());
                },
                tooltip: "Create Playlist",
                child: const Icon(Icons.add),
              )
            : null,
        body: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              final dropdown = DropdownMenu<PlaylistsSort>(
                initialSelection: _viewModel.sort,
                requestFocusOnTap: false,
                leadingIcon: const Icon(Icons.sort),
                width: isDesktop ? 210 : null,
                expandedInsets: !isDesktop ? EdgeInsets.zero : null,
                enableSearch: false,
                dropdownMenuEntries: [
                  const DropdownMenuEntry(
                    value: PlaylistsSort.updated,
                    label: "Updated",
                  ),
                  const DropdownMenuEntry(
                    value: PlaylistsSort.created,
                    label: "Created",
                  ),
                  const DropdownMenuEntry(
                    value: PlaylistsSort.alphabetical,
                    label: "Alphabetical",
                  ),
                  const DropdownMenuEntry(
                    value: PlaylistsSort.songCount,
                    label: "Song count",
                  ),
                  const DropdownMenuEntry(
                    value: PlaylistsSort.duration,
                    label: "Duration",
                  ),
                  const DropdownMenuEntry(
                    value: PlaylistsSort.random,
                    label: "Random",
                  ),
                ],
                onSelected: (PlaylistsSort? sort) {
                  if (sort == null) return;
                  _viewModel.sort = sort;
                },
              );
              final playlists = _viewModel.playlists;
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: isDesktop
                          ? Row(
                              spacing: 32,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 4,
                                  children: [
                                    dropdown,
                                    if (_viewModel.sort != PlaylistsSort.random)
                                      IconButton(
                                        icon: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.sort),
                                            Icon(
                                                _viewModel.sortAscending
                                                    ? Icons.arrow_downward
                                                    : Icons.arrow_upward,
                                                size: 20),
                                          ],
                                        ),
                                        onPressed: () {
                                          _viewModel.sortAscending =
                                              !_viewModel.sortAscending;
                                        },
                                      ),
                                  ],
                                ),
                                Flexible(
                                  fit: FlexFit.loose,
                                  child: Container(
                                    constraints:
                                        const BoxConstraints(maxWidth: 400),
                                    child: Row(
                                      spacing: 8,
                                      children: [
                                        if (!kIsWeb)
                                          IconButton(
                                            icon: Icon(
                                                _viewModel.offline
                                                    ? Icons.wifi_off
                                                    : Icons.wifi,
                                                size: 20),
                                            onPressed: () {
                                              _viewModel.offline =
                                                  !_viewModel.offline;
                                            },
                                          ),
                                        Expanded(
                                          child: SearchInput(
                                            initialValue: _viewModel.searchTerm,
                                            onSearch: (query) {
                                              _viewModel.searchTerm = query;
                                            },
                                          ),
                                        ),
                                        Button(
                                          icon: Icons.add,
                                          onPressed: () {
                                            context.router
                                                .push(CreatePlaylistRoute());
                                          },
                                          outlined: true,
                                          child: const Text("Create"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              spacing: 8,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: dropdown),
                                    if (_viewModel.sort != PlaylistsSort.random)
                                      IconButton(
                                        icon: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.sort),
                                            Icon(
                                                _viewModel.sortAscending
                                                    ? Icons.arrow_downward
                                                    : Icons.arrow_upward,
                                                size: 20),
                                          ],
                                        ),
                                        onPressed: () {
                                          _viewModel.sortAscending =
                                              !_viewModel.sortAscending;
                                        },
                                      ),
                                    IconButton(
                                      icon: Icon(
                                        _viewModel.showFilters
                                            ? Icons.filter_alt
                                            : Icons.filter_alt_outlined,
                                      ),
                                      onPressed: () {
                                        if (_viewModel.showFilters) {
                                          _viewModel.clearFilters();
                                        }
                                        _viewModel.showFilters =
                                            !_viewModel.showFilters;
                                      },
                                    )
                                  ],
                                ),
                                if (_viewModel.showFilters)
                                  Row(
                                    spacing: 8,
                                    children: [
                                      Expanded(
                                        child: SearchInput(
                                          initialValue: _viewModel.searchTerm,
                                          onSearch: (query) {
                                            _viewModel.searchTerm = query;
                                          },
                                          border: true,
                                        ),
                                      ),
                                      if (!kIsWeb)
                                        IconButton(
                                          icon: Icon(
                                              _viewModel.offline
                                                  ? Icons.wifi_off
                                                  : Icons.wifi,
                                              size: 20),
                                          onPressed: () {
                                            _viewModel.offline =
                                                !_viewModel.offline;
                                          },
                                        ),
                                    ],
                                  )
                              ],
                            ),
                    ),
                  ),
                  if (playlists.isEmpty)
                    const SliverToBoxAdapter(
                        child: Center(child: Text("No playlists found"))),
                  SliverPadding(
                    padding: const EdgeInsetsGeometry.all(4),
                    sliver: SliverGrid(
                      gridDelegate: AlbumsGridDelegate(),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= playlists.length) {
                            return null;
                          }
                          final playlist = playlists[index];
                          final p = playlists[index].$1;
                          return PlaylistGridCell(
                            id: p.id,
                            extraInfo: [
                              "Songs: ${p.songCount}",
                            ],
                            coverId: p.coverId,
                            name: p.name,
                            download: p.download,
                            downloadStatus: playlist.$2,
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
                                  successMsg:
                                      "Added '${p.name}' to ${priority ? "priority " : ""}queue");
                            },
                            onAddToPlaylist: () {
                              AddToPlaylistDialog.show(context, p.name,
                                  () => _viewModel.getTracks(p.id));
                            },
                            onDelete: () async {
                              final confirmed =
                                  await ConfirmationDialog.showYesNo(context,
                                      message: "Delete '${p.name}'?");
                              if (!(confirmed ?? false) || !context.mounted) {
                                return;
                              }
                              final result = await _viewModel.delete(p);
                              if (!context.mounted) return;
                              toastResult(context, result,
                                  successMsg: "Deleted playlist '${p.name}'!");
                            },
                            onToggleDownload: () async {
                              if (p.download) {
                                final confirmation =
                                    await ConfirmationDialog.showYesNo(context,
                                        message:
                                            "You won't be able to play this playlist offline anymore.");
                                if (!(confirmation ?? false)) return;
                              }
                              final result = await _viewModel.toggleDownload(p);
                              if (!context.mounted) return;
                              toastResult(context, result,
                                  successMsg: !p.download
                                      ? "Scheduling downloads…"
                                      : null);
                            },
                          );
                        },
                        childCount: playlists.length,
                      ),
                    ),
                  ),
                ],
              );
            }),
      );
    });
  }
}
