import 'package:crossonic/features/search/state/search_bloc.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/subsonic/subsonic.dart';
import 'package:crossonic/services/audio_player/audio_handler.dart';
import 'package:crossonic/widgets/song.dart';
import 'package:crossonic/widgets/song_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  SearchType _selectedType = SearchType.song;

  @override
  void initState() {
    super.initState();
    context.read<SearchBloc>().add(const SearchTextChanged(""));
    context.read<SearchBloc>().add(SearchTypeChanged(_selectedType));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crossonic | Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push("/settings"),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Search...",
                      icon: Icon(Icons.search),
                    ),
                    autofocus: true,
                    restorationId: "search-page-search-input",
                    onChanged: (value) {
                      context.read<SearchBloc>().add(SearchTextChanged(value));
                    },
                  ),
                  const SizedBox(height: 13),
                  SegmentedButton<SearchType>(
                    selected: {_selectedType},
                    onSelectionChanged: (selected) {
                      context
                          .read<SearchBloc>()
                          .add(SearchTypeChanged(selected.first));
                      setState(() {
                        _selectedType = selected.first;
                      });
                    },
                    segments: const <ButtonSegment<SearchType>>[
                      ButtonSegment(
                          value: SearchType.song,
                          label: Text('Songs'),
                          icon: Icon(Icons.music_note)),
                      ButtonSegment(
                          value: SearchType.album,
                          label: Text('Albums'),
                          icon: Icon(Icons.album)),
                      ButtonSegment(
                          value: SearchType.artist,
                          label: Text('Artists'),
                          icon: Icon(Icons.person)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 10),
            BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) {
                if (state.status == FetchStatus.initial ||
                    state.status == FetchStatus.loading ||
                    state.type != _selectedType) {
                  return const CircularProgressIndicator.adaptive();
                }
                if (state.status == FetchStatus.failure) {
                  return const Icon(Icons.wifi_off);
                }
                if (state.results.isEmpty) {
                  return const Text("No results");
                }
                final audioHandler = context.read<CrossonicAudioHandler>();
                final subsonicRepository = context.read<SubsonicRepository>();
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text("Results (${state.results.length}):",
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const SizedBox(height: 8),
                    ...List<Widget>.generate(
                        state.results.length,
                        (i) => switch (state.type) {
                              SearchType.song => Song(
                                  song: state.results[i].media!,
                                  leadingItem: SongLeadingItem.cover,
                                  showArtist: true,
                                  showYear: true,
                                  onTap: () {
                                    audioHandler.playOnNextMediaChange();
                                    audioHandler.mediaQueue.replaceQueue(
                                        state.results
                                            .map((e) => e.media!)
                                            .toList(),
                                        i);
                                  },
                                ),
                              SearchType.album => SongCollection(
                                  name: state.results[i].name,
                                  artist: state.results[i].artist,
                                  artistID: state.results[i].artistID,
                                  coverID: state.results[i].coverID,
                                  isFavorite: state.results[i].isFavorite,
                                  year: state.results[i].year,
                                  onAddToPriorityQueue: () =>
                                      doSomethingWithAlbumSongs(
                                    albumID: state.results[i].id,
                                    albumName: state.results[i].name,
                                    repository: subsonicRepository,
                                    scaffoldMessenger: scaffoldMessenger,
                                    successMessage:
                                        "Added '${state.results[i].name}' to priority queue",
                                    errorMessage: "An unexpected error occured",
                                    callback: (songs) {
                                      audioHandler.mediaQueue
                                          .addAllToPriorityQueue(songs);
                                    },
                                  ),
                                  onAddToQueue: () => doSomethingWithAlbumSongs(
                                    albumID: state.results[i].id,
                                    albumName: state.results[i].name,
                                    repository: subsonicRepository,
                                    scaffoldMessenger: scaffoldMessenger,
                                    successMessage:
                                        "Added '${state.results[i].name}' to queue",
                                    errorMessage: "An unexpected error occured",
                                    callback: (songs) {
                                      audioHandler.mediaQueue.addAll(songs);
                                    },
                                  ),
                                  onTap: () {
                                    context.push(
                                        "/search/album/${state.results[i].id}");
                                  },
                                ),
                              SearchType.artist => SongCollection(
                                  name: state.results[i].name,
                                  coverID: state.results[i].coverID,
                                  isFavorite: state.results[i].isFavorite,
                                  albumCount: state.results[i].albumCount,
                                  onAddToPriorityQueue: () =>
                                      doSomethingWithArtistSongs(
                                    artistID: state.results[i].id,
                                    artistName: state.results[i].name,
                                    repository: subsonicRepository,
                                    scaffoldMessenger: scaffoldMessenger,
                                    successMessage:
                                        "Added '${state.results[i].name}' to priority queue",
                                    errorMessage: "An unexpected error occured",
                                    callback: (songs) {
                                      audioHandler.mediaQueue
                                          .addAllToPriorityQueue(songs);
                                    },
                                  ),
                                  onAddToQueue: () =>
                                      doSomethingWithArtistSongs(
                                    artistID: state.results[i].id,
                                    artistName: state.results[i].name,
                                    repository: subsonicRepository,
                                    scaffoldMessenger: scaffoldMessenger,
                                    successMessage:
                                        "Added '${state.results[i].name}' to queue",
                                    errorMessage: "An unexpected error occured",
                                    callback: (songs) {
                                      audioHandler.mediaQueue.addAll(songs);
                                    },
                                  ),
                                  onTap: () {
                                    context.push(
                                        "/search/artist/${state.results[i].id}");
                                  },
                                )
                            })
                  ],
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Future<void> doSomethingWithAlbumSongs({
    required String albumID,
    required String albumName,
    required void Function(List<Media>) callback,
    required SubsonicRepository repository,
    required ScaffoldMessengerState scaffoldMessenger,
    String? successMessage,
    String? errorMessage,
  }) async {
    try {
      final result = await repository.getAlbum(albumID);
      callback(result.song ?? []);
      if (successMessage != null) {
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(successMessage),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1250),
        ));
      }
    } catch (e) {
      if (errorMessage != null) {
        print(e);
        scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('An unexpected error occured'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 1250),
        ));
      } else {
        rethrow;
      }
    }
  }

  Future<void> doSomethingWithArtistSongs({
    required String artistID,
    required String artistName,
    required void Function(List<Media>) callback,
    required SubsonicRepository repository,
    required ScaffoldMessengerState scaffoldMessenger,
    String? successMessage,
    String? errorMessage,
  }) async {
    try {
      final result = await repository.getArtist(artistID);
      final songLists = await Future.wait(result.album.map((a) async {
        final album = await repository.getAlbum(a.id);
        return album.song ?? <Media>[];
      }));
      callback(songLists.expand((s) => s).toList());
      if (successMessage != null) {
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(successMessage),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1250),
        ));
      }
    } catch (e) {
      if (errorMessage != null) {
        print(e);
        scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('An unexpected error occured'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 1250),
        ));
      } else {
        rethrow;
      }
    }
  }
}
