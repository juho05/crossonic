import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/buttons.dart';
import 'package:crossonic/ui/common/clickable_list_item.dart';
import 'package:crossonic/ui/common/dialogs/add_to_playlist.dart';
import 'package:crossonic/ui/common/dialogs/chooser.dart';
import 'package:crossonic/ui/common/song_list_item.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/ui/songs/songs_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class SongsPage extends StatefulWidget {
  final String mode;
  final String? genre;

  const SongsPage({
    super.key,
    @QueryParam("mode") this.mode = "all",
    @QueryParam("genre") this.genre,
  });

  @override
  State<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  late final SongsViewModel _viewModel;

  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.genre != null) {
      _viewModel = SongsViewModel.genre(
        audioHandler: context.read(),
        subsonic: context.read(),
        genre: widget.genre!,
      )..nextPage();
    } else {
      _viewModel = SongsViewModel(
        audioHandler: context.read(),
        subsonic: context.read(),
        mode: SongsPageMode.values
            .where((m) => m != SongsPageMode.genre)
            .firstWhere(
              (m) => m.name == widget.mode,
              orElse: () => SongsPageMode.all,
            ),
      )..nextPage();
    }
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _controller.dispose();
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
                controller: _controller,
                slivers: [
                  if (_viewModel.mode == SongsPageMode.genre)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          "Genre: ${widget.genre}",
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelLarge!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                        ),
                      ),
                    ),
                  if (_viewModel.mode != SongsPageMode.genre)
                    SliverPadding(
                      padding: const EdgeInsets.all(8.0),
                      sliver: SliverToBoxAdapter(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: DropdownMenu<SongsPageMode>(
                            initialSelection: _viewModel.mode,
                            requestFocusOnTap: false,
                            leadingIcon: const Icon(Icons.sort),
                            enableSearch: false,
                            width: orientation == Orientation.landscape
                                ? 180
                                : null,
                            expandedInsets: orientation == Orientation.portrait
                                ? EdgeInsets.zero
                                : null,
                            dropdownMenuEntries: [
                              if (_viewModel.supportsAllMode)
                                const DropdownMenuEntry(
                                  value: SongsPageMode.all,
                                  label: "All",
                                ),
                              const DropdownMenuEntry(
                                value: SongsPageMode.favorites,
                                label: "Favorites",
                              ),
                              const DropdownMenuEntry(
                                value: SongsPageMode.random,
                                label: "Random",
                              ),
                            ],
                            onSelected: (SongsPageMode? sortMode) {
                              if (sortMode == null) return;
                              _viewModel.mode = sortMode;
                            },
                          ),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Button(
                            icon: Icons.play_arrow,
                            onPressed: () {
                              _viewModel.play(0, false);
                            },
                            child: const Text("Play"),
                          ),
                          Button(
                            icon: Icons.shuffle,
                            onPressed: () {
                              _viewModel.shuffle();
                            },
                            child: const Text("Shuffle"),
                          ),
                          Button(
                            icon: Icons.playlist_play,
                            outlined: true,
                            onPressed: () {
                              _viewModel.addAllToQueue(true);
                              Toast.show(
                                  context, "Added songs to priority queue");
                            },
                            child: const Text("Prio. Queue"),
                          ),
                          Button(
                            icon: Icons.playlist_add,
                            outlined: true,
                            onPressed: () {
                              _viewModel.addAllToQueue(false);
                              Toast.show(context, "Added songs to queue");
                            },
                            child: const Text("Queue"),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverFixedExtentList.builder(
                    itemBuilder: (context, index) {
                      final s = _viewModel.songs[index];
                      return SongListItem(
                        id: s.id,
                        title: s.title,
                        artist: s.displayArtist,
                        coverId: s.coverId,
                        duration: s.duration,
                        year: s.year,
                        onTap: (ctrlPressed) {
                          _viewModel.play(index, ctrlPressed);
                        },
                        onAddToQueue: (priority) {
                          _viewModel.addToQueue(s, priority);
                          Toast.show(context,
                              "Added '${s.title}' to ${priority ? "priority " : ""}queue");
                        },
                        onAddToPlaylist: () {
                          AddToPlaylistDialog.show(context, s.title, [s]);
                        },
                        onGoToAlbum: s.album != null
                            ? () {
                                context.router
                                    .push(AlbumRoute(albumId: s.album!.id));
                              }
                            : null,
                        onGoToArtist: s.artists.isNotEmpty
                            ? () async {
                                final artistId =
                                    await ChooserDialog.chooseArtist(
                                        context, s.artists.toList());
                                if (artistId == null || !context.mounted) {
                                  return;
                                }
                                context.router
                                    .push(ArtistRoute(artistId: artistId));
                              }
                            : null,
                      );
                    },
                    itemExtent: ClickableListItem.verticalExtent,
                    itemCount: _viewModel.songs.length,
                  ),
                  if (_viewModel.status == FetchStatus.success &&
                      _viewModel.songs.isEmpty)
                    const SliverToBoxAdapter(child: Text("No songs available")),
                  if (_viewModel.status == FetchStatus.failure)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Icon(Icons.wifi_off),
                      ),
                    ),
                  if (_viewModel.status == FetchStatus.loading)
                    const SliverToBoxAdapter(
                      child:
                          Center(child: CircularProgressIndicator.adaptive()),
                    ),
                ],
              );
            });
          }),
    );
  }

  void _onScroll() {
    if (_isBottom) _viewModel.nextPage();
  }

  bool get _isBottom {
    if (!_controller.hasClients) return false;
    final maxScroll = _controller.position.maxScrollExtent;
    final currentScroll = _controller.offset;
    return currentScroll >= (maxScroll * 0.8);
  }
}
