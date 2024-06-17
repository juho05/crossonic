import 'package:crossonic/features/search/state/search_bloc.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/api/api.dart';
import 'package:crossonic/services/audio_handler/audio_handler.dart';
import 'package:crossonic/widgets/app_bar.dart';
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

class _SearchPageState extends State<SearchPage> with RestorationMixin {
  SearchType _selectedType = SearchType.song;

  final _controller = RestorableTextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    context.read<SearchBloc>().add(const SearchTextChanged(""));
    context.read<SearchBloc>().add(SearchTypeChanged(_selectedType));
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _controller.value.selection = TextSelection(
            baseOffset: 0, extentOffset: _controller.value.text.length);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createAppBar(context, "Search"),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  TextField(
                    controller: _controller.value,
                    focusNode: _focusNode,
                    decoration: const InputDecoration(
                      labelText: "Search",
                      icon: Icon(Icons.search),
                    ),
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
                final apiRepository = context.read<APIRepository>();
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
                                  id: state.results[i].id,
                                  name: state.results[i].name,
                                  coverID: state.results[i].coverID,
                                  year: state.results[i].year,
                                  artists: state.results[i].artists,
                                  enablePlay: true,
                                  enableShuffle: true,
                                  enableQueue: true,
                                  getSongs: () async => getAlbumSongs(
                                      albumID: state.results[i].id,
                                      repository: apiRepository),
                                  onTap: () {
                                    context.push(
                                        "/search/album/${state.results[i].id}");
                                  },
                                ),
                              SearchType.artist => SongCollection(
                                  id: state.results[i].id,
                                  name: state.results[i].name,
                                  coverID: state.results[i].coverID,
                                  albumCount: state.results[i].albumCount,
                                  enablePlay: true,
                                  enableShuffle: true,
                                  enableQueue: true,
                                  getSongs: () async => getArtistSongs(
                                      artistID: state.results[i].id,
                                      repository: apiRepository),
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

  Future<List<Media>> getAlbumSongs({
    required String albumID,
    required APIRepository repository,
  }) async {
    final result = await repository.getAlbum(albumID);
    return result.song ?? [];
  }

  Future<List<Media>> getArtistSongs({
    required String artistID,
    required APIRepository repository,
  }) async {
    final result = await repository.getArtist(artistID);
    final songLists = await Future.wait((result.album ?? []).map((a) async {
      final album = await repository.getAlbum(a.id);
      return album.song ?? <Media>[];
    }));
    return songLists.expand((s) => s).toList();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  String? get restorationId => "search_page";

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_controller, "search_page_search_controller");
  }
}
