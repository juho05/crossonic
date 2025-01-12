import 'package:crossonic/features/songs/state/songs_cubit.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:crossonic/services/audio_handler/audio_handler.dart';
import 'package:crossonic/components/app_bar.dart';
import 'package:crossonic/components/song.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SongsPage extends StatelessWidget {
  final SongsSort _sortMode;
  const SongsPage({super.key, required SongsSort sortMode})
      : _sortMode = sortMode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SongsCubit(context.read<APIRepository>(), _sortMode)..load(),
      child: SongsPageBody(sortMode: _sortMode),
    );
  }
}

class SongsPageBody extends StatefulWidget {
  final SongsSort _sortMode;
  const SongsPageBody({super.key, required SongsSort sortMode})
      : _sortMode = sortMode;

  @override
  State<SongsPageBody> createState() => _SongsPageBodyState();
}

class _SongsPageBodyState extends State<SongsPageBody> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createAppBar(
        context,
        switch (widget._sortMode) {
          SongsSort.random => "Random Songs",
          _ => "Songs",
        },
      ),
      body: BlocBuilder<SongsCubit, SongsState>(
        builder: (context, state) {
          if (state.songs.isNotEmpty &&
              state.status == FetchStatus.success &&
              _isBottom) {
            Future.delayed(const Duration(milliseconds: 200))
                .then((value) => _onScroll());
          }
          if (state.songs.isEmpty) {
            switch (state.status) {
              case FetchStatus.success:
                return const Center(child: Text("No songs found"));
              case FetchStatus.failure:
                return const Center(child: Icon(Icons.wifi_off));
              default:
                return const Center(
                    child: CircularProgressIndicator.adaptive());
            }
          }
          final audioHandler = context.read<CrossonicAudioHandler>();
          return RefreshIndicator.adaptive(
            onRefresh: () async {
              await context.read<SongsCubit>().load();
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
                            audioHandler.mediaQueue.replaceQueue(state.songs);
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
                              content: Text('Added songs to priority queue'),
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
                    controller: _scrollController,
                    shrinkWrap: true,
                    itemCount: state.songs.length + (state.reachedEnd ? 0 : 1),
                    itemBuilder: (context, index) {
                      if (index == state.songs.length) {
                        if (state.status == FetchStatus.failure) {
                          const Center(child: Icon(Icons.wifi_off));
                        }
                        return const Center(
                            child: CircularProgressIndicator.adaptive());
                      }
                      return Song(
                        song: state.songs[index],
                        leadingItem: SongLeadingItem.cover,
                        showArtist: true,
                        showYear: true,
                        onTap: () async {
                          audioHandler.playOnNextMediaChange();
                          if (HardwareKeyboard.instance.isControlPressed) {
                            audioHandler.mediaQueue
                                .replaceQueue([state.songs[index]]);
                          } else {
                            audioHandler.mediaQueue
                                .replaceQueue(state.songs, index);
                          }
                        },
                      );
                    },
                    restorationId: "songs_page_scroll",
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) context.read<SongsCubit>().nextPage();
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
