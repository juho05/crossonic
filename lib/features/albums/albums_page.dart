import 'package:crossonic/features/albums/state/albums_bloc.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/api/api.dart';
import 'package:crossonic/components/album.dart';
import 'package:crossonic/components/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AlbumsPage extends StatelessWidget {
  final AlbumSortMode _initialSortMode;
  const AlbumsPage({
    super.key,
    required AlbumSortMode sortMode,
  }) : _initialSortMode = sortMode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AlbumsBloc(context.read<APIRepository>()),
      child: Scaffold(
        appBar: createAppBar(context, "Albums"),
        body: AlbumsPageBody(sortMode: _initialSortMode),
      ),
    );
  }
}

class AlbumsPageBody extends StatefulWidget {
  final AlbumSortMode _initialSortMode;
  const AlbumsPageBody({
    super.key,
    required AlbumSortMode sortMode,
  }) : _initialSortMode = sortMode;

  @override
  State<AlbumsPageBody> createState() => _AlbumsPageBodyState();
}

class _AlbumsPageBodyState extends State<AlbumsPageBody> {
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  //DropdownMenuItem(
                  //    value: AlbumSortMode.lastPlayed,
                  //    child: Text("Last played")),
                  DropdownMenuItem(
                      value: AlbumSortMode.rating, child: Text("Rating")),
                  //DropdownMenuItem(
                  //    value: AlbumSortMode.frequent, child: Text("Frequent")),
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
              if (state.albums.isNotEmpty &&
                  state.status == FetchStatus.success &&
                  _isBottom) {
                Future.delayed(const Duration(milliseconds: 200))
                    .then((value) => _onScroll());
              }
              if (state.albums.isEmpty) {
                switch (state.status) {
                  case FetchStatus.success:
                    return const Center(child: Text("No albums found"));
                  case FetchStatus.failure:
                    return const Center(child: Icon(Icons.wifi_off));
                  default:
                    return const Center(
                        child: CircularProgressIndicator.adaptive());
                }
              }
              return Expanded(
                child: GridView.builder(
                  shrinkWrap: true,
                  controller: _scrollController,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    childAspectRatio: 4.0 / 5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: state.reachedEnd
                      ? state.albums.length
                      : state.albums.length + 1,
                  itemBuilder: (context, i) {
                    if (i == state.albums.length) {
                      if (state.status == FetchStatus.failure) {
                        const Center(child: Icon(Icons.wifi_off));
                      }
                      return const Center(
                          child: CircularProgressIndicator.adaptive());
                    }
                    return Album(
                      id: state.albums[i].id,
                      name: state.albums[i].name,
                      coverID: state.albums[i].coverID,
                      artists: state.albums[i].artists.artists.toList(),
                      extraInfo:
                          "${state.albums[i].artists.displayName}${state.albums[i].year != null ? " • ${state.albums[i].year}" : ""}",
                    );
                  },
                ),
              );
            },
          ),
        ],
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
