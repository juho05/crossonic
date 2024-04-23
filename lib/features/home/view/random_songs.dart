import 'package:crossonic/features/home/view/state/random_songs_cubit.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/services/audio_player/audio_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RandomSongs extends StatelessWidget {
  const RandomSongs({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RandomSongsCubit, RandomSongsState>(
      builder: (context, state) {
        return switch (state.status) {
          FetchStatus.initial ||
          FetchStatus.loading ||
          FetchStatus.loadingMore =>
            const Center(child: CircularProgressIndicator.adaptive()),
          FetchStatus.failure => const Center(child: Icon(Icons.wifi_off)),
          FetchStatus.success => Column(
              children: List<Widget>.generate(state.songs.length, (i) {
                return ListTile(
                  title: Text(
                      '${state.songs[i].title} by ${state.songs[i].artist}'),
                  onTap: () async {
                    final audioHandler = context.read<CrossonicAudioHandler>();
                    audioHandler.playOnNextMediaChange();
                    audioHandler.mediaQueue.replaceQueue(state.songs, i);
                  },
                );
              }),
            )
        };
      },
    );
  }
}
