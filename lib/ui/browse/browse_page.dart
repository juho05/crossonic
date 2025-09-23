import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/browse/browse_grid_button.dart';
import 'package:crossonic/ui/browse/browse_viewmodel.dart';
import 'package:crossonic/ui/common/album_list_sliver.dart';
import 'package:crossonic/ui/common/artist_list_sliver.dart';
import 'package:crossonic/ui/common/search_input.dart';
import 'package:crossonic/ui/common/song_list_sliver.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class BrowsePage extends StatefulWidget {
  const BrowsePage({super.key});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  late final BrowseViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = BrowseViewModel(
      subsonicRepository: context.read(),
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
      child: Builder(
        builder: (context) {
          return ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding:
                        const EdgeInsets.only(left: 15, right: 15, bottom: 12),
                    sliver: SliverToBoxAdapter(
                      child: SearchInput(
                        onSearch: (query) {
                          _viewModel.updateSearchText(query);
                        },
                        restorationId: "browse_page_search",
                      ),
                    ),
                  ),
                  if (!_viewModel.searchMode)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 8),
                      sliver: SliverGrid.extent(
                        maxCrossAxisExtent: 150,
                        childAspectRatio: 4.8 / 5,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        children: [
                          BrowseGridButton(
                            icon: Icons.people,
                            text: "Artists",
                            route: ArtistsRoute(),
                          ),
                          BrowseGridButton(
                            icon: Icons.album,
                            text: "Releases",
                            route: AlbumsRoute(),
                          ),
                          BrowseGridButton(
                            icon: Icons.library_music,
                            text: "Songs",
                            route: SongsRoute(),
                          ),
                          const BrowseGridButton(
                            icon: Icons.theater_comedy,
                            text: "Genres",
                            route: GenresRoute(),
                          ),
                          const BrowseGridButton(
                            icon: Icons.calendar_month,
                            text: "Years",
                            route: YearsRoute(),
                          ),
                        ],
                      ),
                    ),
                  if (_viewModel.searchMode &&
                      _viewModel.searchStatus == FetchStatus.failure)
                    const SliverPadding(
                      padding: EdgeInsets.only(top: 12),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: Icon(Icons.wifi_off),
                        ),
                      ),
                    ),
                  if (_viewModel.searchMode &&
                      _viewModel.searchStatus == FetchStatus.loading)
                    const SliverPadding(
                      padding: EdgeInsets.only(top: 12),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      ),
                    ),
                  if (_viewModel.searchMode &&
                      _viewModel.searchStatus == FetchStatus.success &&
                      _viewModel.artists.isEmpty &&
                      _viewModel.albums.isEmpty &&
                      _viewModel.songs.isEmpty)
                    const SliverPadding(
                      padding: EdgeInsets.only(top: 12),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: Text("No results"),
                        ),
                      ),
                    ),
                  if (_viewModel.searchMode && _viewModel.artists.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: BrowseSearchResultSeparator(
                        title: "Artists",
                        icon: Icons.person,
                      ),
                    ),
                  if (_viewModel.searchMode && _viewModel.artists.isNotEmpty)
                    ArtistListSliver(
                      artists: _viewModel.artists,
                    ),
                  if (_viewModel.searchMode && _viewModel.albums.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: BrowseSearchResultSeparator(
                        title: "Releases",
                        icon: Icons.album,
                      ),
                    ),
                  if (_viewModel.searchMode && _viewModel.albums.isNotEmpty)
                    AlbumListSliver(
                      albums: _viewModel.albums,
                    ),
                  if (_viewModel.searchMode && _viewModel.songs.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: BrowseSearchResultSeparator(
                        title: "Songs",
                        icon: Icons.music_note,
                      ),
                    ),
                  if (_viewModel.searchMode && _viewModel.songs.isNotEmpty)
                    SongListSliver(songs: _viewModel.songs),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class BrowseSearchResultSeparator extends StatelessWidget {
  final String title;
  final IconData icon;
  const BrowseSearchResultSeparator({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        spacing: 8,
        children: [
          Icon(icon),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge,
          )
        ],
      ),
    );
  }
}
