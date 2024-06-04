import 'package:crossonic/features/home/view/state/random_songs_cubit.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:crossonic/services/audio_handler/audio_handler.dart';
import 'package:crossonic/widgets/app_bar.dart';
import 'package:crossonic/widgets/song.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RandomSongsPage extends StatelessWidget {
  const RandomSongsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createAppBar(context, "Random Songs"),
      body: BlocProvider(
        create: (context) =>
            RandomSongsCubit(context.read<APIRepository>())..fetch(300),
        child: BlocBuilder<RandomSongsCubit, RandomSongsState>(
          builder: (context, state) {
            final audioHandler = context.read<CrossonicAudioHandler>();
            return switch (state.status) {
              FetchStatus.initial ||
              FetchStatus.loading =>
                const Center(child: CircularProgressIndicator.adaptive()),
              FetchStatus.failure => const Center(child: Icon(Icons.wifi_off)),
              FetchStatus.success => RefreshIndicator.adaptive(
                  onRefresh: () async {
                    await context.read<RandomSongsCubit>().fetch(300);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Play'),
                                onPressed: () {
                                  audioHandler.playOnNextMediaChange();
                                  audioHandler.mediaQueue
                                      .replaceQueue(state.songs);
                                },
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.playlist_play),
                                label: const Text('Prio. Queue'),
                                onPressed: () {
                                  audioHandler.mediaQueue
                                      .addAllToPriorityQueue(state.songs);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content:
                                        Text('Added songs to priority queue'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(milliseconds: 1250),
                                  ));
                                },
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.playlist_add_outlined),
                                label: const Text('Queue'),
                                onPressed: () {
                                  audioHandler.mediaQueue.addAll(state.songs);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text('Added songs to queue'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(milliseconds: 1250),
                                  ));
                                },
                              )
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: state.songs.length,
                          itemBuilder: (context, index) => Song(
                            song: state.songs[index],
                            leadingItem: SongLeadingItem.cover,
                            showArtist: true,
                            showYear: true,
                            onTap: () async {
                              audioHandler.playOnNextMediaChange();
                              audioHandler.mediaQueue
                                  .replaceQueue(state.songs, index);
                            },
                          ),
                          restorationId: "random_songs_page_scroll",
                        ),
                      ),
                    ],
                  ),
                )
            };
          },
        ),
      ),
    );
  }
}
