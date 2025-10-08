import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:crossonic/data/repositories/settings/home_page_layout.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/albums/albums_viewmodel.dart';
import 'package:crossonic/ui/artists/artists_viewmodel.dart';
import 'package:crossonic/ui/home/components/artist_list.dart';
import 'package:crossonic/ui/home/components/artist_list_viewmodel.dart';
import 'package:crossonic/ui/home/components/favorite_artists_datasource.dart';
import 'package:crossonic/ui/home/components/favorite_songs_datasource.dart';
import 'package:crossonic/ui/home/components/random_artists_datasource.dart';
import 'package:crossonic/ui/home/components/random_songs_datasource.dart';
import 'package:crossonic/ui/home/components/release_list.dart';
import 'package:crossonic/ui/home/components/release_list_viewmodel.dart';
import 'package:crossonic/ui/home/components/releases_datasource.dart';
import 'package:crossonic/ui/home/components/song_list.dart';
import 'package:crossonic/ui/home/components/song_list_viewmodel.dart';
import 'package:crossonic/ui/home/home_viewmodel.dart';
import 'package:crossonic/ui/songs/songs_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(builder: (context, viewModel, _) {
      return Material(
        child: viewModel.content.isNotEmpty
            ? RefreshIndicator.adaptive(
                onRefresh: () async {
                  viewModel.refresh(true);
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: CustomScrollView(
                  slivers: viewModel.content
                      .mapIndexed((i, o) => SliverPadding(
                            key: ValueKey("$i-${o.name}"),
                            padding: const EdgeInsets.only(bottom: 4),
                            sliver: _optionToWidget(
                                o, viewModel.refreshStream, viewModel.seed),
                          ))
                      .toList(),
                ),
              )
            : const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    "Visit Settings‑>Home Layout to configure the content of this page.",
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
      );
    });
  }

  Widget _optionToWidget(
      HomeContentOption option, Stream refreshStream, String? seed) {
    switch (option) {
      case HomeContentOption.favoriteSongs:
        return _songsWidget(option, refreshStream, null);
      case HomeContentOption.randomSongs:
        return _songsWidget(
            option,
            refreshStream
                .where((refreshRandom) => refreshRandom || seed != null),
            seed);
      case HomeContentOption.recentlyAddedReleases:
      case HomeContentOption.favoriteReleases:
      case HomeContentOption.recentlyPlayedReleases:
      case HomeContentOption.frequentlyPlayedReleases:
        return _releasesWidget(option, refreshStream, null);
      case HomeContentOption.randomReleases:
        return _releasesWidget(
            option,
            refreshStream
                .where((refreshRandom) => refreshRandom || seed != null),
            seed);
      case HomeContentOption.favoriteArtists:
        return _artistsWidget(option, refreshStream, null);
      case HomeContentOption.randomArtists:
        return _artistsWidget(
            option,
            refreshStream
                .where((refreshRandom) => refreshRandom || seed != null),
            seed);
    }
  }

  Widget _songsWidget(
      HomeContentOption option, Stream? refreshStream, String? seed) {
    return ChangeNotifierProvider(
      create: (context) => HomeSongListViewModel(
        refreshStream: refreshStream,
        dataSource: switch (option) {
          HomeContentOption.randomSongs =>
            RandomSongsDataSource(repository: context.read()),
          HomeContentOption.favoriteSongs =>
            FavoriteSongsDataSource(repository: context.read()),
          _ =>
            throw Exception("Unknown home content song option: ${option.name}")
        },
        homeViewModel: context.read(),
      ),
      child: HomeSongList(
        title: HomeLayoutSettings.optionTitle(option),
        route: SongsRoute(
          mode: switch (option) {
            HomeContentOption.randomSongs => SongsPageMode.random,
            HomeContentOption.favoriteSongs => SongsPageMode.favorites,
            _ => throw Exception(
                "Unknown home content song option: ${option.name}"),
          }
              .name,
          initialSeed: seed,
        ),
      ),
    );
  }

  Widget _releasesWidget(
      HomeContentOption option, Stream? refreshStream, String? seed) {
    return ChangeNotifierProvider(
      create: (context) => HomeReleaseListViewModel(
        refreshStream: refreshStream,
        dataSource: switch (option) {
          HomeContentOption.recentlyAddedReleases => ReleasesDataSource(
              mode: AlbumsSortMode.recentlyAdded, repository: context.read()),
          HomeContentOption.randomReleases => ReleasesDataSource(
              mode: AlbumsSortMode.random, repository: context.read()),
          HomeContentOption.favoriteReleases => ReleasesDataSource(
              mode: AlbumsSortMode.starred, repository: context.read()),
          HomeContentOption.recentlyPlayedReleases => ReleasesDataSource(
              mode: AlbumsSortMode.recentlyPlayed, repository: context.read()),
          HomeContentOption.frequentlyPlayedReleases => ReleasesDataSource(
              mode: AlbumsSortMode.frequentlyPlayed,
              repository: context.read()),
          _ => throw Exception(
              "Unknown home content release option: ${option.name}")
        },
        homeViewModel: context.read(),
      ),
      child: HomeReleaseList(
        title: HomeLayoutSettings.optionTitle(option),
        route: AlbumsRoute(
          mode: switch (option) {
            HomeContentOption.recentlyAddedReleases =>
              AlbumsPageMode.recentlyAdded,
            HomeContentOption.randomReleases => AlbumsPageMode.random,
            HomeContentOption.favoriteReleases => AlbumsPageMode.favorites,
            HomeContentOption.recentlyPlayedReleases =>
              AlbumsPageMode.recentlyPlayed,
            HomeContentOption.frequentlyPlayedReleases =>
              AlbumsPageMode.frequentlyPlayed,
            _ => throw Exception(
                "Unknown home content release option: ${option.name}")
          }
              .name,
          initialSeed: seed,
        ),
      ),
    );
  }

  Widget _artistsWidget(
      HomeContentOption option, Stream? refreshStream, String? seed) {
    return ChangeNotifierProvider(
      create: (context) => HomeArtistListViewModel(
        refreshStream: refreshStream,
        dataSource: switch (option) {
          HomeContentOption.randomArtists =>
            RandomArtistsDataSource(repository: context.read()),
          HomeContentOption.favoriteArtists =>
            FavoriteArtistsDataSource(repository: context.read()),
          _ => throw Exception(
              "Unknown home content artist option: ${option.name}")
        },
        homeViewModel: context.read(),
      ),
      child: HomeArtistList(
        title: HomeLayoutSettings.optionTitle(option),
        route: ArtistsRoute(
          initialSort: switch (option) {
            HomeContentOption.randomArtists => ArtistsPageMode.random,
            HomeContentOption.favoriteArtists => ArtistsPageMode.favorites,
            _ => throw Exception(
                "Unknown home content artist option: ${option.name}")
          }
              .name,
          initialSeed: seed,
        ),
      ),
    );
  }
}
