import 'package:crossonic/features/browse/browse_content.dart';
import 'package:crossonic/features/browse/state/browse_bloc.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/api/api.dart';
import 'package:crossonic/services/audio_handler/audio_handler.dart';
import 'package:crossonic/components/app_bar.dart';
import 'package:crossonic/components/song.dart';
import 'package:crossonic/components/song_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class BrowsePage extends StatefulWidget {
  const BrowsePage({super.key});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> with RestorationMixin {
  BrowseType _selectedType = BrowseType.song;

  final _controller = RestorableTextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    context.read<BrowseBloc>().add(const SearchTextChanged(""));
    context.read<BrowseBloc>().add(BrowseTypeChanged(_selectedType));
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
      appBar: createAppBar(context, "Browse"),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  SegmentedButton<BrowseType>(
                    selected: {_selectedType},
                    onSelectionChanged: (selected) {
                      context
                          .read<BrowseBloc>()
                          .add(BrowseTypeChanged(selected.first));
                      setState(() {
                        _selectedType = selected.first;
                      });
                    },
                    segments: const <ButtonSegment<BrowseType>>[
                      ButtonSegment(
                          value: BrowseType.song,
                          label: Text('Songs'),
                          icon: Icon(Icons.music_note)),
                      ButtonSegment(
                          value: BrowseType.album,
                          label: Text('Albums'),
                          icon: Icon(Icons.album)),
                      ButtonSegment(
                          value: BrowseType.artist,
                          label: Text('Artists'),
                          icon: Icon(Icons.person)),
                    ],
                  ),
                  const SizedBox(height: 13),
                  TextField(
                    controller: _controller.value,
                    focusNode: _focusNode,
                    decoration: const InputDecoration(
                      labelText: "Search",
                      icon: Icon(Icons.search),
                    ),
                    restorationId: "browse-page-search-input",
                    onChanged: (value) {
                      context.read<BrowseBloc>().add(SearchTextChanged(value));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            BlocBuilder<BrowseBloc, BrowseState>(
              builder: (context, state) {
                if (state.showGrid) {
                  return BrowseContent(type: _selectedType);
                }
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
                              BrowseType.song => Song(
                                  song: state.results[i].media!,
                                  leadingItem: SongLeadingItem.cover,
                                  showArtist: true,
                                  showYear: true,
                                  onTap: () {
                                    audioHandler.playOnNextMediaChange();
                                    if (HardwareKeyboard
                                        .instance.isControlPressed) {
                                      audioHandler.mediaQueue.replaceQueue(
                                          [state.results[i].media!]);
                                    } else {
                                      audioHandler.mediaQueue.replaceQueue(
                                          state.results
                                              .map((e) => e.media!)
                                              .toList(),
                                          i);
                                    }
                                  },
                                ),
                              BrowseType.album => SongCollection(
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
                                        "/browse/album/${state.results[i].id}");
                                  },
                                ),
                              BrowseType.artist => SongCollection(
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
                                        "/browse/artist/${state.results[i].id}");
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
  String? get restorationId => "browse_page";

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_controller, "browse_page_search_controller");
  }
}
