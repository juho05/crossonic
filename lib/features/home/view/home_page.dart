import 'package:crossonic/features/home/view/state/home_cubit.dart';
import 'package:crossonic/services/audio_player/audio_handler.dart';
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
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return RefreshIndicator.adaptive(
            child: switch (state.randomSongsStatus) {
              RandomSongsStatus.initial ||
              RandomSongsStatus.loading =>
                const Center(child: CircularProgressIndicator.adaptive()),
              RandomSongsStatus.failure =>
                const Center(child: Icon(Icons.wifi_off)),
              RandomSongsStatus.success => ListView.builder(
                  itemCount: state.randomSongs.length,
                  itemBuilder: (context, i) {
                    return ListTile(
                      title: Text(
                          '${state.randomSongs[i].title} by ${state.randomSongs[i].artist}'),
                      onTap: () {
                        final audioHandler =
                            context.read<CrossonicAudioHandler>();
                        audioHandler.mediaQueue
                            .replaceQueue(state.randomSongs.sublist(i));
                        audioHandler.play();
                      },
                    );
                  },
                )
            },
            onRefresh: () async {
              await context.read<HomeCubit>().fetchRandomSongs();
            },
          );
        },
      ),
    );
  }
}
