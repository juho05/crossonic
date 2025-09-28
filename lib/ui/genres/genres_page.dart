import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/albums/albums_viewmodel.dart';
import 'package:crossonic/ui/genres/genres_viewmodel.dart';
import 'package:crossonic/ui/main/layout_mode.dart';
import 'package:crossonic/ui/songs/songs_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class GenresPage extends StatefulWidget {
  const GenresPage({super.key});

  @override
  State<GenresPage> createState() => _GenresPageState();
}

class _GenresPageState extends State<GenresPage> {
  late final GenresViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = GenresViewModel(
      subsonic: context.read(),
    )..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          final albumTextSize =
              _viewModel.largestAlbumCount.toString().length * 10;
          final songTextSize =
              _viewModel.largestSongCount.toString().length * 10;
          return RefreshIndicator.adaptive(
            onRefresh: () => _viewModel.load(),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DropdownMenu<GenresSortMode>(
                          initialSelection: _viewModel.sortMode,
                          leadingIcon: const Icon(Icons.sort),
                          width: 240,
                          requestFocusOnTap: false,
                          enableSearch: false,
                          dropdownMenuEntries: [
                            const DropdownMenuEntry(
                              value: GenresSortMode.alphabetical,
                              label: "Alphabetical",
                            ),
                            const DropdownMenuEntry(
                              value: GenresSortMode.songCount,
                              label: "Song Count",
                            ),
                            const DropdownMenuEntry(
                              value: GenresSortMode.albumCount,
                              label: "Release Count",
                            ),
                            const DropdownMenuEntry(
                              value: GenresSortMode.random,
                              label: "Random",
                            ),
                          ],
                          onSelected: (GenresSortMode? sortMode) {
                            if (sortMode == null) return;
                            _viewModel.sortMode = sortMode;
                          },
                        ),
                        Text(
                          "${_viewModel.genres.length} Genres",
                          style: textTheme.labelLarge!.copyWith(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  sliver: SliverFixedExtentList.builder(
                    itemCount: _viewModel.genres.length,
                    itemExtent: 48,
                    itemBuilder: (context, index) {
                      final g = _viewModel.genres[index];
                      return Material(
                        child: LayoutModeBuilder(builder: (context, isDesktop) {
                          return Row(
                            spacing: 8,
                            children: [
                              Expanded(
                                child: Text(
                                  g.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodyLarge!
                                      .copyWith(fontSize: 16),
                                ),
                              ),
                              SizedBox(
                                width: isDesktop
                                    ? albumTextSize + 100
                                    : albumTextSize + 50,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: Material(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainer,
                                    child: InkWell(
                                      onTap: () {
                                        context.router.push(AlbumsRoute(
                                          mode: AlbumsPageMode.genre.name,
                                          genre: g.name,
                                        ));
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          spacing: 4,
                                          children: [
                                            const Icon(Icons.album),
                                            if (isDesktop)
                                              Text("Releases: ${g.albumCount}")
                                            else
                                              Text("${g.albumCount}")
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                  width: isDesktop
                                      ? songTextSize + 110
                                      : songTextSize + 60,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5),
                                    child: Material(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainer,
                                      child: InkWell(
                                        onTap: () {
                                          context.router.push(SongsRoute(
                                            mode: SongsPageMode.genre.name,
                                            genre: g.name,
                                          ));
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            spacing: 4,
                                            children: [
                                              const Icon(Icons.music_note),
                                              if (isDesktop)
                                                Text("Songs: ${g.songCount}")
                                              else
                                                Text("${g.songCount}")
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  )),
                            ],
                          );
                        }),
                      );
                    },
                  ),
                ),
                if (_viewModel.status == FetchStatus.success &&
                    _viewModel.genres.isEmpty)
                  const SliverToBoxAdapter(
                      child: Center(child: Text("No genres found"))),
                if (_viewModel.status == FetchStatus.failure)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Icon(Icons.wifi_off),
                    ),
                  ),
                if (_viewModel.status == FetchStatus.loading)
                  const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
