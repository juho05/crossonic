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
import 'package:crossonic/ui/common/dialogs/dialog.dart';
import 'package:crossonic/ui/common/search_input.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AddToPlaylistDialog {
  static Future<void> show(
    BuildContext context,
    String? collectionName,
    SongLoader loader,
  ) async {
    final AddToPlaylistViewModel viewModel = AddToPlaylistViewModel(
      repository: context.read(),
      songLoader: loader,
    );
    return showDialog(
      context: context,
      builder: (context) => CrossonicDialog(
        child: _AddToPlaylistDialogContent(
          viewModel: viewModel,
          collectionName: collectionName,
        ),
      ),
    );
  }
}

class _AddToPlaylistDialogContent extends StatefulWidget {
  final AddToPlaylistViewModel _viewModel;
  final String? _collectionName;

  const _AddToPlaylistDialogContent({
    required AddToPlaylistViewModel viewModel,
    String? collectionName,
  }) : _viewModel = viewModel,
       _collectionName = collectionName;

  @override
  State<_AddToPlaylistDialogContent> createState() =>
      _AddToPlaylistDialogContentState();
}

class _AddToPlaylistDialogContentState
    extends State<_AddToPlaylistDialogContent> {
  final FocusScopeNode _textFieldFocusScope = FocusScopeNode();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FocusScope(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyUpEvent &&
            event.logicalKey == LogicalKeyboardKey.enter) {
          _submit(context);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: ListenableBuilder(
        listenable: widget._viewModel,
        builder: (context, _) {
          return Container(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Builder(
              builder: (context) {
                if (widget._viewModel.status == FetchStatus.failure) {
                  return Container(
                    constraints: const BoxConstraints(maxHeight: 244),
                    child: const Center(child: Icon(Icons.wifi_off)),
                  );
                }
                if (widget._viewModel.status != FetchStatus.success) {
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
                                CreatePlaylistRoute(
                                  songs: widget._viewModel.songs,
                                ),
                              );
                            },
                            child: const Text("Create"),
                          ),
                        ],
                      ),
                      FocusScope(
                        node: _textFieldFocusScope,
                        onKeyEvent: (node, event) {
                          if (event is KeyUpEvent &&
                              event.logicalKey == LogicalKeyboardKey.enter) {
                            node.unfocus();
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: SearchInput(
                          onSearch: (query) => widget._viewModel.search(query),
                          debounce: const Duration(milliseconds: 100),
                          onTapOutside: () {
                            _textFieldFocusScope.unfocus();
                          },
                          onClearButtonPressed: () {
                            _textFieldFocusScope.unfocus();
                          },
                        ),
                      ),
                      Flexible(
                        child: Container(
                          constraints: BoxConstraints(
                            maxHeight:
                                _PlaylistListItem.verticalExtent *
                                max(1, widget._viewModel.playlists.length),
                          ),
                          child: widget._viewModel.playlists.isNotEmpty
                              ? ListView.builder(
                                  itemExtent: _PlaylistListItem.verticalExtent,
                                  itemCount: widget._viewModel.playlists.length,
                                  itemBuilder: (context, index) {
                                    final p =
                                        widget._viewModel.playlists[index];
                                    return _PlaylistListItem(
                                      playlist: p,
                                      selected: widget
                                          ._viewModel
                                          .selectedPlaylists
                                          .contains(p),
                                      onSelect: () {
                                        widget._viewModel.toggleSelection(p);
                                      },
                                      songInPlaylistCount:
                                          widget
                                              ._viewModel
                                              .songInPlaylistCounts[p.id] ??
                                          0,
                                      onRemoveSong: () async {
                                        final yes =
                                            await ConfirmationDialog.showYesNo(
                                              context,
                                              message:
                                                  "Remove '${widget._viewModel.songs.first.title}' from '${p.name}'?",
                                            );
                                        if (yes ?? false) {
                                          await widget._viewModel
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
                      const Divider(height: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Add ${widget._viewModel.songCount} song${widget._viewModel.songCount != 1 ? "s" : ""} "
                            "to ${widget._viewModel.selectedPlaylists.length} playlist${widget._viewModel.selectedPlaylists.length != 1 ? "s" : ""}.",
                          ),
                          Button(
                            onPressed:
                                widget._viewModel.selectedPlaylists.isNotEmpty
                                ? () => _submit(context)
                                : null,
                            child: const Text("Add"),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (widget._viewModel.selectedPlaylists.isEmpty) return;
    Navigator.pop(context);
    final Set<Playlist> addAll = {};
    final Set<Playlist> addNone = {};
    final successCount = await widget._viewModel.addSongsToPlaylists((
      p,
      s,
    ) async {
      if (addAll.contains(p)) {
        return true;
      }
      if (addNone.contains(p)) {
        return false;
      }
      final option = await showAdaptiveDialog<int>(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return AlertDialog.adaptive(
            title: const Text("Duplicate detected"),
            content: Text(
              "The song '${s.title}' is already contained in the playlist ${p.name}.\nAdd anyway?",
            ),
            actions: [
              AdaptiveDialogAction(
                onPressed: () => Navigator.pop(context, 0),
                child: const Text("Never"),
              ),
              AdaptiveDialogAction(
                onPressed: () => Navigator.pop(context, 1),
                child: const Text("No"),
              ),
              AdaptiveDialogAction(
                onPressed: () => Navigator.pop(context, 2),
                child: const Text("Yes"),
              ),
              AdaptiveDialogAction(
                onPressed: () => Navigator.pop(context, 3),
                child: const Text("Always"),
              ),
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
    if (successCount == widget._viewModel.selectedPlaylists.length) {
      if (successCount == 1) {
        Toast.show(
          context,
          "Added ${widget._collectionName ?? "songs"} to ${widget._viewModel.selectedPlaylists.first.name}",
        );
      } else {
        Toast.show(
          context,
          "Added ${widget._collectionName ?? "songs"} to $successCount playlists",
        );
      }
    } else {
      Toast.show(
        context,
        "Added ${widget._collectionName ?? "songs"} to $successCount/${widget._viewModel.selectedPlaylists.length} playlists",
      );
    }
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
      leading: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Icon(selected ? Icons.check_box : Icons.check_box_outline_blank),
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
          ? _SongCountBadge(count: songInPlaylistCount, onRemove: onRemoveSong)
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
    final color = _hovering
        ? Colors.red
        : Theme.of(context).colorScheme.primary;
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
                    : Text("${widget.count}", style: textStyle),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
