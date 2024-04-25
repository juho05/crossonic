import 'package:crossonic/features/home/view/state/random_songs_cubit.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/services/audio_player/audio_handler.dart';
import 'package:crossonic/widgets/song.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RandomSongs extends StatelessWidget {
  const RandomSongs({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onBackground,
            textStyle: theme.textTheme.headlineSmall!.copyWith(fontSize: 20),
          ),
          child: const Row(
            children: [
              Text("Random songs"),
              Icon(
                Icons.arrow_forward_ios,
              )
            ],
          ),
        ),
        BlocBuilder<RandomSongsCubit, RandomSongsState>(
          builder: (context, state) {
            return switch (state.status) {
              FetchStatus.initial ||
              FetchStatus.loading ||
              FetchStatus.loadingMore =>
                const Center(child: CircularProgressIndicator.adaptive()),
              FetchStatus.failure => const Center(child: Icon(Icons.wifi_off)),
              FetchStatus.success => Column(
                  children: List<Widget>.generate(state.songs.length, (i) {
                    return Song(
                      song: state.songs[i],
                      leadingItem: SongLeadingItem.cover,
                      showArtist: true,
                      showYear: true,
                      onTap: () async {
                        final audioHandler =
                            context.read<CrossonicAudioHandler>();
                        audioHandler.playOnNextMediaChange();
                        audioHandler.mediaQueue.replaceQueue(state.songs, i);
                      },
                    );
                  }),
                )
            };
          },
        ),
      ],
    );
  }
}
