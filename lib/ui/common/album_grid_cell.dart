import 'package:crossonic/ui/common/album_grid_cell_viewmodel.dart';
import 'package:crossonic/ui/common/context_menu_button.dart';
import 'package:crossonic/ui/common/cover_art_decorated.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AlbumGridCell extends StatefulWidget {
  final String id;
  final String name;
  final List<String> extraInfo;
  final String? coverId;

  final void Function()? onTap;
  final void Function()? onPlay;
  final void Function()? onShuffle;
  final void Function(bool priority)? onAddToQueue;
  final void Function()? onAddToPlaylist;
  final void Function()? onGoToArtist;

  const AlbumGridCell({
    super.key,
    required this.id,
    required this.name,
    required this.extraInfo,
    this.coverId,
    this.onTap,
    this.onPlay,
    this.onShuffle,
    this.onAddToQueue,
    this.onAddToPlaylist,
    this.onGoToArtist,
  });

  @override
  State<AlbumGridCell> createState() => _AlbumGridCellState();
}

class _AlbumGridCellState extends State<AlbumGridCell> {
  late final AlbumGridCellViewModel _viewModel;

  final _popupMenuButton = GlobalKey<State>();

  @override
  void initState() {
    super.initState();
    _viewModel = AlbumGridCellViewModel(
      favoritesRepository: context.read(),
      albumId: widget.id,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final menuOptions = [
          if (widget.onPlay != null)
            ContextMenuOption(
              title: "Play",
              icon: Icons.play_arrow,
              onSelected: widget.onPlay,
            ),
          if (widget.onShuffle != null)
            ContextMenuOption(
              title: "Shuffle",
              icon: Icons.shuffle,
              onSelected: widget.onShuffle,
            ),
          if (widget.onAddToQueue != null)
            ContextMenuOption(
              title: "Add to priority queue",
              icon: Icons.playlist_play,
              onSelected: () => widget.onAddToQueue!(true),
            ),
          if (widget.onAddToQueue != null)
            ContextMenuOption(
              title: "Add to queue",
              icon: Icons.playlist_add,
              onSelected: () => widget.onAddToQueue!(false),
            ),
          ContextMenuOption(
            icon: _viewModel.favorite ? Icons.heart_broken : Icons.favorite,
            title: _viewModel.favorite
                ? "Remove from favorites"
                : "Add to favorites",
            onSelected: () async {
              final result = await _viewModel.toggleFavorite();
              if (!context.mounted) return;
              toastResult(context, result);
            },
          ),
          if (widget.onAddToQueue != null)
            ContextMenuOption(
              title: "Add to playlist",
              icon: Icons.playlist_add,
              onSelected: widget.onAddToPlaylist,
            ),
          if (widget.onGoToArtist != null)
            ContextMenuOption(
              title: "Go to artist",
              icon: Icons.person,
              onSelected: widget.onGoToArtist,
            ),
        ];
        return WithContextMenu(
          popupMenuButtonKey: _popupMenuButton,
          options: menuOptions,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CoverArtDecorated(
                          borderRadius: BorderRadius.circular(7),
                          isFavorite: _viewModel.favorite,
                          placeholderIcon: Icons.album,
                          coverId: widget.coverId,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.name,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w400,
                            fontSize: constraints.maxHeight * 0.07,
                          ),
                        ),
                        Text(
                          widget.extraInfo.join(" • "),
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w300,
                            fontSize: constraints.maxHeight * 0.06,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: widget.onTap,
                  ),
                ),
              ),
              AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(builder: (context, constraints) {
                  final largeLayout = constraints.maxHeight > 256;
                  return Padding(
                    padding: EdgeInsets.all(8 + (largeLayout ? 10 : 6)),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Material(
                        type: MaterialType.transparency,
                        child: Ink(
                          decoration: ShapeDecoration(
                            color: Colors.black.withAlpha(90),
                            shape: const CircleBorder(),
                          ),
                          child: SizedBox(
                            width: largeLayout ? 40 : 30,
                            height: largeLayout ? 40 : 30,
                            child: ContextMenuButton(
                              popupMenuButtonKey: _popupMenuButton,
                              options: menuOptions,
                              padding: const EdgeInsets.all(0),
                              icon: Icon(
                                Icons.more_vert,
                                size: largeLayout ? 26 : 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
