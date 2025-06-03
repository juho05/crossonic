import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/albums/albums_viewmodel.dart';
import 'package:crossonic/ui/genres/genres_viewmodel.dart';
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
    return Material(
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          if (_viewModel.status == FetchStatus.failure) {
            return const Center(child: Icon(Icons.wifi_off));
          }
          if (_viewModel.status != FetchStatus.success) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (_viewModel.genres.isEmpty) {
            return const Center(child: Text("No genres available"));
          }
          return OrientationBuilder(builder: (context, orientation) {
            final albumTextSize =
                _viewModel.largestAlbumCount.toString().length * 10;
            final songTextSize =
                _viewModel.largestSongCount.toString().length * 10;
            return ListView.builder(
              itemCount: _viewModel.genres.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final textTheme = Theme.of(context).textTheme;
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DropdownMenu<GenresSortMode>(
                          initialSelection: _viewModel.sortMode,
                          leadingIcon: const Icon(Icons.sort),
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
                  );
                } else {
                  index--;
                }
                final g = _viewModel.genres[index];
                return ListTile(
                  title: Text(g.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    spacing: 8,
                    children: [
                      SizedBox(
                        width: orientation == Orientation.landscape
                            ? albumTextSize + 100
                            : albumTextSize + 50,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Material(
                            color:
                                Theme.of(context).colorScheme.surfaceContainer,
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
                                    if (orientation == Orientation.landscape)
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
                          width: orientation == Orientation.landscape
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
                                      if (orientation == Orientation.landscape)
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
                  ),
                );
              },
            );
          });
        },
      ),
    );
  }
}
