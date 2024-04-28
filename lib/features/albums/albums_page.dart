import 'package:crossonic/features/albums/state/albums_bloc.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/widgets/album.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AlbumsPage extends StatefulWidget {
  final AlbumSortMode _initialSortMode;
  const AlbumsPage({
    super.key,
    required AlbumSortMode sortMode,
  }) : _initialSortMode = sortMode;

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  final _scrollController = ScrollController();
  AlbumSortMode? _sortMode;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    _sortMode ??= widget._initialSortMode;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crossonic | Albums'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push("/settings"),
          )
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              Row(
                children: [
                  DropdownButton<AlbumSortMode>(
                    icon: const Icon(Icons.sort),
                    items: const [
                      DropdownMenuItem(
                          value: AlbumSortMode.random, child: Text("Random")),
                      DropdownMenuItem(
                          value: AlbumSortMode.added, child: Text("Added")),
                      DropdownMenuItem(
                          value: AlbumSortMode.lastPlayed,
                          child: Text("Last played")),
                      DropdownMenuItem(
                          value: AlbumSortMode.rating, child: Text("Rating")),
                      DropdownMenuItem(
                          value: AlbumSortMode.frequent,
                          child: Text("Frequent")),
                      DropdownMenuItem(
                          value: AlbumSortMode.alphabetical,
                          child: Text("Alphabetical")),
                      DropdownMenuItem(
                          value: AlbumSortMode.releaseDate,
                          child: Text("Release date")),
                    ],
                    hint: const Text('Sort mode'),
                    value: _sortMode,
                    onChanged: (AlbumSortMode? value) {
                      if (value == _sortMode) return;
                      setState(() {
                        _sortMode = value;
                      });
                    },
                  )
                ],
              ),
              const SizedBox(height: 8),
              BlocBuilder<AlbumsBloc, AlbumsState>(
                builder: (context, state) {
                  if (_sortMode != state.sortMode) {
                    context
                        .read<AlbumsBloc>()
                        .add(AlbumSortModeSelected(_sortMode!));
                    return const CircularProgressIndicator.adaptive();
                  }
                  return Column(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 15,
                            runSpacing: 12,
                            alignment: WrapAlignment.spaceEvenly,
                            children: List<Widget>.generate(
                                state.albums.length,
                                (i) => SizedBox(
                                      height: 200,
                                      child: Album(
                                        id: state.albums[i].id,
                                        name: state.albums[i].name,
                                        coverID: state.albums[i].coverID,
                                        extraInfo:
                                            "${state.albums[i].artist}${state.albums[i].year != null ? " • ${state.albums[i].year}" : ""}",
                                      ),
                                    )),
                          ),
                        ],
                      ),
                      if (state.status == FetchStatus.loading)
                        const Padding(
                          padding: EdgeInsets.only(top: 15, bottom: 8),
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      if (state.status == FetchStatus.failure)
                        const Padding(
                          padding: EdgeInsets.only(top: 15, bottom: 8),
                          child: Icon(Icons.wifi_off),
                        ),
                    ],
                  );
                },
              )
            ],
          ),
        ),
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
    if (_isBottom) context.read<AlbumsBloc>().add(AlbumsNextPageFetched());
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.8);
  }
}
