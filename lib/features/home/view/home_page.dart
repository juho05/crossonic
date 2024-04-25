import 'package:crossonic/features/home/view/home_carousel.dart';
import 'package:crossonic/features/home/view/random_songs.dart';
import 'package:crossonic/features/home/view/recently_added_albums.dart';
import 'package:crossonic/features/home/view/state/random_songs_cubit.dart';
import 'package:crossonic/features/home/view/state/recently_added_albums_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crossonic | Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push("/settings"),
          )
        ],
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: () async {
          context.read<RecentlyAddedAlbumsCubit>().fetch(15);
          context.read<RandomSongsCubit>().fetch(50);
        },
        child: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeCarousel(
                title: "Recently added albums",
                content: RecentlyAddedAlbums(),
              ),
              SizedBox(height: 8),
              RandomSongs(),
            ],
          ),
        ),
      ),
    );
  }
}
