import 'package:auto_route/auto_route.dart';
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
                      .map((o) => SliverPadding(
                            padding: const EdgeInsets.only(bottom: 4),
                            sliver: _optionToWidget(o, viewModel.refreshStream),
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

  Widget _optionToWidget(HomeContentOption option, Stream refreshStream) {
    switch (option) {
      case HomeContentOption.favoriteSongs:
        return _songsWidget(option, refreshStream);
      case HomeContentOption.randomSongs:
        return _songsWidget(
            option, refreshStream.where((refreshRandom) => refreshRandom));
      case HomeContentOption.recentlyAddedReleases:
      case HomeContentOption.favoriteReleases:
      case HomeContentOption.recentlyPlayedReleases:
      case HomeContentOption.frequentlyPlayedReleases:
        return _releasesWidget(option, refreshStream);
      case HomeContentOption.randomReleases:
        return _releasesWidget(
            option, refreshStream.where((refreshRandom) => refreshRandom));
      case HomeContentOption.favoriteArtists:
        return _artistsWidget(option, refreshStream);
      case HomeContentOption.randomArtists:
        return _artistsWidget(
            option, refreshStream.where((refreshRandom) => refreshRandom));
    }
  }

  Widget _songsWidget(HomeContentOption option, Stream? refreshStream) {
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
        ),
      ),
    );
  }

  Widget _releasesWidget(HomeContentOption option, Stream? refreshStream) {
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
        ),
      ),
    );
  }

  Widget _artistsWidget(HomeContentOption option, Stream? refreshStream) {
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
        ),
      ),
    );
  }
}
