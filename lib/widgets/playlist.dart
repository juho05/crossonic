import 'package:crossonic/exceptions.dart';
import 'package:crossonic/repositories/api/models/playlist_model.dart';
import 'package:crossonic/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/widgets/confirmation.dart';
import 'package:crossonic/widgets/cover_art.dart';
import 'package:crossonic/widgets/large_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class PlaylistGridCell extends StatefulWidget {
  final Playlist playlist;
  const PlaylistGridCell({
    super.key,
    required this.playlist,
  });

  @override
  State<PlaylistGridCell> createState() => _PlaylistGridCellState();
}

class _PlaylistGridCellState extends State<PlaylistGridCell> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textTheme = Theme.of(context).textTheme;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              context.push("/home/playlist/${widget.playlist.id}");
            },
            child: SizedBox(
              width: constraints.maxHeight * (4 / 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CoverArtWithMenu(
                    id: widget.playlist.id,
                    name: widget.playlist.name,
                    size: constraints.maxHeight * (4 / 5),
                    resolution: const CoverResolution.medium(),
                    enablePlay: true,
                    enableShuffle: true,
                    enableQueue: true,
                    enableToggleFavorite: false,
                    coverID: widget.playlist.coverArt,
                    getSongs: () async => (await context
                            .read<PlaylistRepository>()
                            .getPlaylistThenUpdate(widget.playlist.id))
                        .entry!,
                    onDelete: () async {
                      if (!(await ConfirmationDialog.showCancel(context)))
                        return;
                      try {
                        if (context.mounted) {
                          await context
                              .read<PlaylistRepository>()
                              .delete(widget.playlist.id);
                        }
                      } on ServerUnreachableException {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(const SnackBar(
                                content: Text("Cannot connect to server")));
                        }
                      } catch (e) {
                        print(e);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(const SnackBar(
                                content: Text("An unexpected error occured")));
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.playlist.name,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: constraints.maxHeight * 0.07,
                    ),
                  ),
                  Text(
                    "Songs: ${widget.playlist.songCount}", // TODO: consider adding playlist duration
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w300,
                      fontSize: constraints.maxHeight * 0.06,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
