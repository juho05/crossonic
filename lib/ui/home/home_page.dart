import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/home/components/album_list.dart';
import 'package:crossonic/ui/home/components/album_list_viewmodel.dart';
import 'package:crossonic/ui/home/components/random_songs_datasource.dart';
import 'package:crossonic/ui/home/components/recent_albums_datasource.dart';
import 'package:crossonic/ui/home/components/song_list.dart';
import 'package:crossonic/ui/home/components/song_list_viewmodel.dart';
import 'package:crossonic/ui/songs/songs_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChangeNotifierProvider(
              create: (context) => HomeAlbumListViewModel(
                dataSource:
                    RecentlyAddedAlbumsDataSource(repository: context.read()),
                audioHandler: context.read(),
                subsonicRepository: context.read(),
              ),
              builder: (context, _) => HomeAlbumList(
                title: "Recently added albums",
                route: AlbumsRoute(
                  mode: AlbumsSortMode.recentlyAdded.name,
                ),
                viewModel: context.read(),
              ),
            ),
            ChangeNotifierProvider(
              create: (context) => HomeSongListViewModel(
                dataSource: RandomSongsDataSource(repository: context.read()),
                audioHandler: context.read(),
              ),
              builder: (context, _) => HomeSongList(
                title: "Random songs",
                route: SongsRoute(
                  mode: SongsPageMode.random.name,
                ),
                viewModel: context.read(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
