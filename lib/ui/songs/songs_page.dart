import 'package:auto_route/auto_route.dart';
import 'package:crossonic/ui/common/buttons.dart';
import 'package:crossonic/ui/common/refresh_scroll_view.dart';
import 'package:crossonic/ui/common/song_list_sliver.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/ui/main/layout_mode.dart';
import 'package:crossonic/ui/songs/songs_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class SongsPage extends StatefulWidget {
  final String mode;
  final String? genre;
  final String? initialSeed;

  const SongsPage({
    super.key,
    @QueryParam("mode") this.mode = "all",
    @QueryParam("genre") this.genre,
    this.initialSeed,
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
        initialSeed: widget.initialSeed,
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
          return LayoutModeBuilder(
            builder: (context, isDesktop) {
              return RefreshScrollView(
                onRefresh: () => _viewModel.refresh(),
                controller: _controller,
                slivers: [
                  if (_viewModel.mode == SongsPageMode.genre)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Genre: ${widget.genre}",
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelLarge!
                                    .copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                              ),
                            ),
                            if (isDesktop)
                              IconButton(
                                onPressed: () => _viewModel.refresh(),
                                icon: const Icon(Icons.refresh),
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (_viewModel.mode != SongsPageMode.genre)
                    SliverPadding(
                      padding: const EdgeInsets.all(8.0),
                      sliver: SliverToBoxAdapter(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            spacing: 8,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: DropdownMenu<SongsPageMode>(
                                  initialSelection: _viewModel.mode,
                                  requestFocusOnTap: false,
                                  leadingIcon: const Icon(Icons.sort),
                                  enableSearch: false,
                                  width: isDesktop ? 190 : null,
                                  expandedInsets: !isDesktop
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
                              if (isDesktop)
                                IconButton(
                                  onPressed: () => _viewModel.refresh(),
                                  icon: const Icon(Icons.refresh),
                                ),
                            ],
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
                              _viewModel.play();
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
                                context,
                                "Added songs to priority queue",
                              );
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
                  SongListSliver(
                    songs: _viewModel.songs,
                    fetchStatus: _viewModel.status,
                  ),
                ],
              );
            },
          );
        },
      ),
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
