import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/albums_grid_delegate.dart';
import 'package:crossonic/ui/common/buttons.dart';
import 'package:crossonic/ui/common/dialogs/add_to_playlist.dart';
import 'package:crossonic/ui/common/dialogs/confirmation.dart';
import 'package:crossonic/ui/common/playlist_grid_cell.dart';
import 'package:crossonic/ui/playlists/playlists_viewmodel.dart';
import 'package:crossonic/utils/result.dart';
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
    return OrientationBuilder(builder: (context, orientation) {
      return Scaffold(
        floatingActionButton: orientation == Orientation.portrait
            ? FloatingActionButton(
                onPressed: () {
                  context.router.push(const CreatePlaylistRoute());
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
                expandedInsets: orientation == Orientation.portrait
                    ? EdgeInsets.zero
                    : null,
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
                    label: "Song Count",
                  ),
                  const DropdownMenuEntry(
                    value: PlaylistsSort.duration,
                    label: "Duration",
                  ),
                  const DropdownMenuEntry(
                    value: PlaylistsSort.random,
                    label: "Random",
                  ),
                  if (!kIsWeb)
                    const DropdownMenuEntry(
                      value: PlaylistsSort.downloaded,
                      label: "Downloaded",
                    ),
                ],
                onSelected: (PlaylistsSort? sort) {
                  if (sort == null) return;
                  _viewModel.sort = sort;
                },
              );
              final playlists = _viewModel.sort == PlaylistsSort.downloaded
                  ? _viewModel.playlists.where((p) => p.$1.download).toList()
                  : _viewModel.playlists;
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: orientation == Orientation.landscape
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              spacing: 8,
                              children: [
                                dropdown,
                                Button(
                                  icon: Icons.add,
                                  onPressed: () {
                                    context.router
                                        .push(const CreatePlaylistRoute());
                                  },
                                  outlined: true,
                                  child: const Text("Create"),
                                )
                              ],
                            )
                          : Align(
                              alignment: Alignment.centerLeft,
                              child: dropdown,
                            ),
                    ),
                  ),
                  if (playlists.isEmpty)
                    const SliverToBoxAdapter(
                        child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("No playlists available"),
                    )),
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
                            onAddToPlaylist: () async {
                              final result = await _viewModel.getTracks(p.id);
                              if (!context.mounted) return;
                              switch (result) {
                                case Err():
                                  toastResult(context, result);
                                case Ok():
                                  AddToPlaylistDialog.show(
                                      context, p.name, result.value);
                              }
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
