import 'package:crossonic/features/lyrics/state/lyrics_cubit.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:crossonic/services/audio_handler/audio_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LyricsPage extends StatelessWidget {
  const LyricsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LyricsCubit(
          audioHandler: context.read<CrossonicAudioHandler>(),
          apiRepository: context.read<APIRepository>()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Crossonic | Lyrics'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => context.push("/settings"),
            )
          ],
        ),
        body: BlocBuilder<LyricsCubit, LyricsState>(
          builder: (context, state) {
            if (state.status == FetchStatus.initial ||
                state.status == FetchStatus.loading) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }
            if (state.status == FetchStatus.failure) {
              return const Center(child: Icon(Icons.wifi_off));
            }
            if (state.noSong) {
              return const Center(child: Text("No active song"));
            }
            if (state.lines.isEmpty) {
              return const Center(child: Text("No lyrics"));
            }
            final textTheme = Theme.of(context).textTheme;
            return SingleChildScrollView(
              restorationId: "lyrics_scroll",
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 8, right: 8, bottom: 32, top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: state.lines
                      .map(
                        (l) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            l,
                            textAlign: TextAlign.center,
                            softWrap: true,
                            style: textTheme.headlineMedium!
                                .copyWith(fontSize: 24),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
