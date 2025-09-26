import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
import 'package:crossonic/data/services/opensubsonic/exceptions.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/clickable_list_item.dart';
import 'package:crossonic/ui/common/collection_page.dart';
import 'package:crossonic/ui/common/cover_art_decorated.dart';
import 'package:crossonic/ui/common/dialogs/add_to_playlist.dart';
import 'package:crossonic/ui/common/dialogs/confirmation.dart';
import 'package:crossonic/ui/common/dialogs/media_info.dart';
import 'package:crossonic/ui/common/song_list_item.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:crossonic/ui/playlist/playlist_viewmodel.dart';
import 'package:crossonic/utils/format.dart';
import 'package:crossonic/utils/result.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class PlaylistPage extends StatefulWidget {
  final String playlistId;

  const PlaylistPage({super.key, @PathParam("id") required this.playlistId});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  late final PlaylistViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PlaylistViewModel(
      playlistId: widget.playlistId,
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
    return Material(
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          if (_viewModel.playlist == null) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          final playlist = _viewModel.playlist!;
          final songs = _viewModel.tracks;

          Widget songListItem({
            required int index,
          }) {
            final t = songs[index];
            final s = t.$1;
            return SongListItem(
              key: ValueKey("$index-${s.id}"),
              song: s,
              reorderIndex: index,
              showPlaybackStatus: !_viewModel.editMode,
              downloadStatus: playlist.download ? t.$2 : DownloadStatus.none,
              editMode: _viewModel.editMode,
              showDragHandle: _viewModel.editMode,
              enableLongPressReorder: true,
              showRemoveButton: _viewModel.editMode,
              onRemove: () async {
                final result = await _viewModel.remove(index);
                if (!context.mounted) return;
                toastResult(context, result);
              },
              onTap: (ctrlPressed) {
                _viewModel.play(index, ctrlPressed);
              },
            );
          }

          return CollectionPage(
            name: playlist.name,
            description: playlist.comment,
            descriptionTitle: "Description",
            onChangeName: _viewModel.editMode
                ? () {
                    context.router.push(UpdatePlaylistRoute(
                      playlistId: playlist.id,
                      playlistName: playlist.name,
                      playlistDescription: playlist.comment ?? "",
                    ));
                  }
                : null,
            onChangeDescription: _viewModel.editMode
                ? () {
                    context.router.push(UpdatePlaylistRoute(
                      playlistId: playlist.id,
                      playlistName: playlist.name,
                      playlistDescription: playlist.comment ?? "",
                    ));
                  }
                : null,
            cover: CoverArtDecorated(
              placeholderIcon: Icons.album,
              borderRadius: BorderRadius.circular(10),
              isFavorite: false,
              coverId: playlist.coverId,
              uploading: _viewModel.uploadingCover,
              downloadStatus: _viewModel.downloadStatus,
              bottomRight:
                  _viewModel.editMode && _viewModel.changeCoverSupported
                      ? OnCoverMenuButton(
                          tooltip: "Change cover",
                          menuOptions: [
                            ContextMenuOption(
                              title: playlist.coverId != null
                                  ? "Change cover"
                                  : "Set cover",
                              icon: Icons.image_outlined,
                              onSelected: () async {
                                final result = await _viewModel.changeCover();
                                if (!context.mounted) return;
                                if (result is ImageTooLargeException) {
                                  Toast.show(context,
                                      "Image too large: max 15 MB allowed");
                                } else {
                                  toastResult(context, result);
                                }
                              },
                            ),
                            if (playlist.coverId != null)
                              ContextMenuOption(
                                title: "Remove cover",
                                icon: Icons.hide_image_outlined,
                                onSelected: () async {
                                  final result = await _viewModel.removeCover();
                                  if (!context.mounted) return;
                                  toastResult(context, result);
                                },
                              ),
                          ],
                          icon: Icons.edit,
                        )
                      : null,
              menuOptions: !_viewModel.editMode
                  ? [
                      ContextMenuOption(
                        title: "Play",
                        icon: Icons.play_arrow,
                        onSelected: () {
                          _viewModel.play();
                        },
                      ),
                      ContextMenuOption(
                        title: "Shuffle",
                        icon: Icons.shuffle,
                        onSelected: () {
                          _viewModel.shuffle();
                        },
                      ),
                      ContextMenuOption(
                        title: "Add to priority queue",
                        icon: Icons.playlist_play,
                        onSelected: () {
                          _viewModel.addToQueue(true);
                          Toast.show(context,
                              "Added '${playlist.name}' to priority queue");
                        },
                      ),
                      ContextMenuOption(
                        title: "Add to queue",
                        icon: Icons.playlist_add,
                        onSelected: () {
                          _viewModel.addToQueue(false);
                          Toast.show(
                              context, "Added '${playlist.name}' to queue");
                        },
                      ),
                      ContextMenuOption(
                        title: "Add to playlist",
                        icon: Icons.playlist_add,
                        onSelected: () {
                          AddToPlaylistDialog.show(
                              context,
                              playlist.name,
                              () async => Result.ok(
                                  _viewModel.tracks.map((t) => t.$1)));
                        },
                      ),
                      if (!kIsWeb)
                        ContextMenuOption(
                          title: playlist.download
                              ? "Remove Download"
                              : "Download",
                          icon:
                              playlist.download ? Icons.delete : Icons.download,
                          onSelected: () async {
                            if (playlist.download) {
                              final confirmation =
                                  await ConfirmationDialog.showYesNo(context,
                                      message:
                                          "You won't be able to play this playlist offline anymore.");
                              if (!(confirmation ?? false)) return;
                            }
                            final result = await _viewModel.toggleDownload();
                            if (!context.mounted) return;
                            toastResult(context, result,
                                successMsg: !playlist.download
                                    ? "Scheduling downloads…"
                                    : null);
                          },
                        ),
                      ContextMenuOption(
                        title: "Edit",
                        icon: Icons.edit,
                        onSelected: () {
                          _viewModel.editMode = true;
                        },
                      ),
                      ContextMenuOption(
                        title: "Info",
                        icon: Icons.info_outline,
                        onSelected: () {
                          MediaInfoDialog.showPlaylist(context, playlist.id);
                        },
                      ),
                      ContextMenuOption(
                        title: "Delete",
                        icon: Icons.delete_forever,
                        onSelected: () async {
                          final confirmed = await ConfirmationDialog.showYesNo(
                              context,
                              message: "Delete '${playlist.name}'?");
                          if (!(confirmed ?? false) || !context.mounted) {
                            return;
                          }
                          final result = await _viewModel.delete();
                          if (!context.mounted) return;
                          context.maybePop();
                          toastResult(context, result,
                              successMsg:
                                  "Deleted playlist '${playlist.name}'!");
                        },
                      )
                    ]
                  : [
                      ContextMenuOption(
                        title: playlist.coverId != null
                            ? "Change cover"
                            : "Set cover",
                        icon: Icons.image_outlined,
                        onSelected: () async {
                          final result = await _viewModel.changeCover();
                          if (!context.mounted) return;
                          switch (result) {
                            case Err():
                              if (result.error is ImageTooLargeException) {
                                Toast.show(context,
                                    "Image too large: max 15 MB allowed");
                                return;
                              }
                              if (result.error is SubsonicException) {
                                Toast.show(context,
                                    "Failed to change cover: ${(result.error as SubsonicException).message}");
                                return;
                              }
                              toastResult(context, result);
                            case Ok():
                          }
                        },
                      ),
                      if (playlist.coverId != null)
                        ContextMenuOption(
                          title: "Remove cover",
                          icon: Icons.hide_image_outlined,
                          onSelected: () async {
                            final result = await _viewModel.removeCover();
                            if (!context.mounted) return;
                            toastResult(context, result);
                          },
                        ),
                      ContextMenuOption(
                        title: "Stop Edit",
                        icon: Icons.edit_off,
                        onSelected: () {
                          _viewModel.editMode = false;
                        },
                      ),
                      ContextMenuOption(
                        title: "Delete",
                        icon: Icons.delete_forever,
                        onSelected: () async {
                          final confirmed = await ConfirmationDialog.showYesNo(
                              context,
                              message: "Delete '${playlist.name}'?");
                          if (!(confirmed ?? false) || !context.mounted) {
                            return;
                          }
                          final result = await _viewModel.delete();
                          if (!context.mounted) return;
                          context.maybePop();
                          toastResult(context, result,
                              successMsg:
                                  "Deleted playlist '${playlist.name}'!");
                        },
                      )
                    ],
            ),
            extraInfo: [
              CollectionExtraInfo(
                text: formatDuration(playlist.duration, long: true),
              ),
              if (_viewModel.downloadStatus == DownloadStatus.downloading)
                CollectionExtraInfo(
                  text:
                      "Downloading: ${_viewModel.downloadedTracks}/${playlist.songCount}",
                ),
            ],
            actions: [
              CollectionAction(
                title: "Play",
                highlighted: true,
                icon: Icons.play_arrow,
                onClick: () {
                  _viewModel.play();
                },
              ),
              CollectionAction(
                title: "Shuffle",
                highlighted: true,
                icon: Icons.shuffle,
                onClick: () {
                  _viewModel.shuffle();
                },
              ),
              CollectionAction(
                title: "Prio. Queue",
                icon: Icons.playlist_play,
                onClick: () {
                  _viewModel.addToQueue(true);
                  Toast.show(
                      context, "Added '${playlist.name}' to priority queue");
                },
              ),
              CollectionAction(
                title: "Queue",
                icon: Icons.playlist_add,
                onClick: () {
                  _viewModel.addToQueue(false);
                  Toast.show(context, "Added '${playlist.name}' to queue");
                },
              ),
              CollectionAction(
                title: _viewModel.editMode ? "Stop Edit" : "Edit",
                icon: _viewModel.editMode ? Icons.edit_off : Icons.edit,
                color: _viewModel.editMode ? Colors.red : null,
                onClick: () {
                  _viewModel.editMode = !_viewModel.editMode;
                },
              ),
            ],
            contentTitle: "Tracks (${songs.length})",
            contentSliver: SliverReorderableList(
              itemExtent: ClickableListItem.verticalExtent,
              proxyDecorator: (child, index, animation) =>
                  songListItem(index: index),
              itemCount: songs.length,
              onReorder: (oldIndex, newIndex) async {
                final result = await _viewModel.reorder(oldIndex, newIndex);
                if (!context.mounted) return;
                toastResult(context, result);
              },
              onReorderStart: (_) {
                _viewModel.editMode = true;
              },
              itemBuilder: (context, index) => songListItem(index: index),
            ),
          );
        },
      ),
    );
  }
}
