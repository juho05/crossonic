import 'dart:math' show max;

import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/playlist/models/playlist.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/adaptive_dialog_action.dart';
import 'package:crossonic/ui/common/buttons.dart';
import 'package:crossonic/ui/common/clickable_list_item.dart';
import 'package:crossonic/ui/common/cover_art.dart';
import 'package:crossonic/ui/common/dialogs/add_to_playlist_viewmodel.dart';
import 'package:crossonic/ui/common/dialogs/confirmation.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddToPlaylistDialog {
  static Future<void> show(
      BuildContext context, String? collectionName, SongLoader loader) async {
    final AddToPlaylistViewModel viewModel = AddToPlaylistViewModel(
      repository: context.read(),
      songLoader: loader,
    );
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        child: _AddToPlaylistDialogContent(viewModel: viewModel),
      ),
    );
  }
}

class _AddToPlaylistDialogContent extends StatelessWidget {
  final AddToPlaylistViewModel _viewModel;
  final String? _collectionName;
  const _AddToPlaylistDialogContent(
      {required AddToPlaylistViewModel viewModel, String? collectionName})
      : _viewModel = viewModel,
        _collectionName = collectionName;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Container(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Builder(builder: (context) {
            if (_viewModel.status == FetchStatus.failure) {
              return Container(
                constraints: const BoxConstraints(maxHeight: 244),
                child: const Center(
                  child: Icon(Icons.wifi_off),
                ),
              );
            }
            if (_viewModel.status != FetchStatus.success) {
              return Container(
                constraints: const BoxConstraints(maxHeight: 244),
                child: const Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Add to playlist",
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.headlineSmall,
                      ),
                      Button(
                        icon: Icons.add,
                        onPressed: () {
                          Navigator.pop(context);
                          context.router.push(
                              CreatePlaylistRoute(songs: _viewModel.songs));
                        },
                        child: const Text("Create"),
                      ),
                    ],
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      suffixIcon: Icon(Icons.search),
                      labelText: "Search",
                    ),
                    onChanged: (value) => _viewModel.search(value),
                  ),
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: _PlaylistListItem.verticalExtent *
                            max(1, _viewModel.playlists.length),
                      ),
                      child: _viewModel.playlists.isNotEmpty
                          ? ListView.builder(
                              itemExtent: _PlaylistListItem.verticalExtent,
                              itemCount: _viewModel.playlists.length,
                              itemBuilder: (context, index) {
                                final p = _viewModel.playlists[index];
                                return _PlaylistListItem(
                                  playlist: p,
                                  selected:
                                      _viewModel.selectedPlaylists.contains(p),
                                  onSelect: () {
                                    _viewModel.toggleSelection(p);
                                  },
                                  songInPlaylistCount:
                                      _viewModel.songInPlaylistCounts[p.id] ??
                                          0,
                                  onRemoveSong: () async {
                                    final yes = await ConfirmationDialog.showYesNo(
                                        context,
                                        message:
                                            "Remove '${_viewModel.songs.first.title}' from '${p.name}'?");
                                    if (yes ?? false) {
                                      await _viewModel
                                          .removeSongFromPlaylist(p);
                                    }
                                  },
                                );
                              },
                            )
                          : const Center(
                              child: Text("No playlists found."),
                            ),
                    ),
                  ),
                  const Divider(
                    height: 1,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          "Add ${_viewModel.songCount} song${_viewModel.songCount != 1 ? "s" : ""} "
                          "to ${_viewModel.selectedPlaylists.length} playlist${_viewModel.selectedPlaylists.length != 1 ? "s" : ""}."),
                      Button(
                        onPressed: _viewModel.selectedPlaylists.isNotEmpty
                            ? () async {
                                final Set<Playlist> addAll = {};
                                final Set<Playlist> addNone = {};
                                final successCount = await _viewModel
                                    .addSongsToPlaylists((p, s) async {
                                  if (addAll.contains(p)) {
                                    return true;
                                  }
                                  if (addNone.contains(p)) {
                                    return false;
                                  }
                                  final option = await showAdaptiveDialog<int>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog.adaptive(
                                        title: const Text("Duplicate detected"),
                                        content: Text(
                                            "The song '${s.title}' is already contained in the playlist ${p.name}.\nAdd anyway?"),
                                        actions: [
                                          AdaptiveDialogAction(
                                            onPressed: () =>
                                                Navigator.pop(context, 0),
                                            child: const Text("Never"),
                                          ),
                                          AdaptiveDialogAction(
                                            onPressed: () =>
                                                Navigator.pop(context, 1),
                                            child: const Text("No"),
                                          ),
                                          AdaptiveDialogAction(
                                            onPressed: () =>
                                                Navigator.pop(context, 2),
                                            child: const Text("Yes"),
                                          ),
                                          AdaptiveDialogAction(
                                            onPressed: () =>
                                                Navigator.pop(context, 3),
                                            child: const Text("Always"),
                                          )
                                        ],
                                      );
                                    },
                                  );
                                  switch (option) {
                                    case 0:
                                      addNone.add(p);
                                      return false;
                                    case 1:
                                      return false;
                                    case 2:
                                      return true;
                                    case 3:
                                      addAll.add(p);
                                      return true;
                                  }
                                  return null;
                                });
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                if (successCount ==
                                    _viewModel.selectedPlaylists.length) {
                                  Toast.show(context,
                                      "Added ${_collectionName ?? "songs"} to $successCount playlist${successCount != 1 ? "s" : ""}");
                                } else {
                                  Toast.show(context,
                                      "Added ${_collectionName ?? "songs"} to $successCount/${_viewModel.selectedPlaylists.length} playlists");
                                }
                              }
                            : null,
                        child: const Text("Add"),
                      )
                    ],
                  )
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

class _PlaylistListItem extends StatelessWidget {
  static const double verticalExtent = ClickableListItem.verticalExtent;

  final Playlist playlist;
  final bool selected;
  final int songInPlaylistCount;

  final void Function() onSelect;
  final void Function() onRemoveSong;

  const _PlaylistListItem({
    required this.playlist,
    required this.selected,
    required this.onSelect,
    required this.songInPlaylistCount,
    required this.onRemoveSong,
  });

  @override
  Widget build(BuildContext context) {
    return ClickableListItem(
      title: playlist.name,
      extraInfo: ["Songs: ${playlist.songCount}"],
      onTap: onSelect,
      transparent: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Icon(
                selected ? Icons.check_box : Icons.check_box_outline_blank,
              ),
              CoverArt(
                placeholderIcon: Icons.album,
                coverId: playlist.coverId,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          ),
        ),
      ),
      trailing: songInPlaylistCount > 0
          ? _SongCountBadge(
              count: songInPlaylistCount,
              onRemove: onRemoveSong,
            )
          : null,
    );
  }
}

class _SongCountBadge extends StatefulWidget {
  final int count;
  final void Function() onRemove;

  const _SongCountBadge({required this.count, required this.onRemove});

  @override
  State<_SongCountBadge> createState() => _SongCountBadgeState();
}

class _SongCountBadgeState extends State<_SongCountBadge> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final color =
        _hovering ? Colors.red : Theme.of(context).colorScheme.primary;
    final textStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        );
    return ClipRRect(
      borderRadius: BorderRadiusGeometry.circular(25),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onHover: (value) {
            setState(() {
              _hovering = value;
            });
          },
          onTap: widget.onRemove,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: 25,
              constraints: const BoxConstraints(minWidth: 25),
              decoration: BoxDecoration(
                borderRadius: BorderRadiusGeometry.circular(25),
                border: Border.all(color: color),
              ),
              child: Center(
                  child: _hovering
                      ? Icon(Icons.remove, color: color)
                      : Text("${widget.count}", style: textStyle)),
            ),
          ),
        ),
      ),
    );
  }
}
