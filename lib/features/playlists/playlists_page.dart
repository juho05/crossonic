import 'package:crossonic/features/playlists/state/playlists_cubit.dart';
import 'package:crossonic/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/components/app_bar.dart';
import 'package:crossonic/components/playlist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class PlaylistsPage extends StatelessWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createAppBar(context, "Playlists"),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push("/playlists/createPlaylist");
        },
        tooltip: "Create playlist",
        child: const Icon(Icons.create),
      ),
      body: RepositoryProvider(
        create: (context) => PlaylistsCubit(context.read<PlaylistRepository>()),
        child: Builder(
          builder: (context) {
            return BlocBuilder<PlaylistsCubit, PlaylistsState>(
              builder: (context, state) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  child: RefreshIndicator(
                    onRefresh: () async =>
                        await context.read<PlaylistRepository>().fetch(),
                    child: GridView.builder(
                      restorationId: "playlists_grid_view",
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 180,
                        childAspectRatio: 4.0 / 5,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                      ),
                      itemCount: state.playlists.length,
                      itemBuilder: (context, i) => PlaylistGridCell(
                        playlist: state.playlists[i],
                        downloadStatus: state.playlistDownloads
                                .containsKey(state.playlists[i].id)
                            ? state.playlistDownloads[state.playlists[i].id]
                            : null,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
