import 'package:crossonic/features/albums/state/albums_bloc.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/api/api.dart';
import 'package:crossonic/components/album.dart';
import 'package:crossonic/components/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AlbumsPage extends StatelessWidget {
  final AlbumSortMode _sortMode;
  const AlbumsPage({
    super.key,
    required AlbumSortMode sortMode,
  }) : _sortMode = sortMode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AlbumsBloc(context.read<APIRepository>())
        ..add(AlbumSortModeSelected(_sortMode)),
      child: Scaffold(
        appBar: createAppBar(
          context,
          switch (_sortMode) {
            AlbumSortMode.added => "Recently Added Albums",
            AlbumSortMode.frequent => "Frequently Played Albums",
            AlbumSortMode.lastPlayed => "Last Played Albums",
            AlbumSortMode.random => "Random Albums",
            AlbumSortMode.releaseDate => "Albums by Release Date",
            _ => "Albums",
          },
        ),
        body: const AlbumsPageBody(),
      ),
    );
  }
}

class AlbumsPageBody extends StatefulWidget {
  const AlbumsPageBody({super.key});

  @override
  State<AlbumsPageBody> createState() => _AlbumsPageBodyState();
}

class _AlbumsPageBodyState extends State<AlbumsPageBody> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: BlocBuilder<AlbumsBloc, AlbumsState>(
        builder: (context, state) {
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
          return RefreshIndicator.adaptive(
            onRefresh: () async {
              context.read<AlbumsBloc>().add(AlbumsRefresh());
            },
            child: GridView.builder(
              shrinkWrap: true,
              controller: _scrollController,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                childAspectRatio: 4.0 / 5,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
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
