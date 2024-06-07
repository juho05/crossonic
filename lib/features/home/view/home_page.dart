import 'package:crossonic/features/home/view/home_carousel.dart';
import 'package:crossonic/features/home/view/random_songs.dart';
import 'package:crossonic/features/home/view/recently_added_albums.dart';
import 'package:crossonic/features/home/view/state/random_songs_cubit.dart';
import 'package:crossonic/features/home/view/state/recently_added_albums_cubit.dart';
import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:crossonic/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final apiRepository = context.read<APIRepository>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => RandomSongsCubit(apiRepository)..fetch(50),
        ),
        BlocProvider(
          create: (_) => RecentlyAddedAlbumsCubit(apiRepository)..fetch(15),
        ),
      ],
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: createAppBar(context, "Home"),
          body: RefreshIndicator.adaptive(
            onRefresh: () async {
              context.read<RecentlyAddedAlbumsCubit>().fetch(15);
              context.read<RandomSongsCubit>().fetch(50);
            },
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HomeCarousel(
                    title: "Recently added albums",
                    content: const RecentlyAddedAlbums(),
                    onMore: () {
                      context.push("/home/albums/added");
                    },
                  ),
                  const SizedBox(height: 8),
                  const RandomSongs(),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
