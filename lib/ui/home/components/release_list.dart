import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/album_grid_cell.dart';
import 'package:crossonic/ui/common/dialogs/add_to_playlist.dart';
import 'package:crossonic/ui/common/dialogs/chooser.dart';
import 'package:crossonic/ui/home/components/release_list_viewmodel.dart';
import 'package:crossonic/ui/home/components/home_page_component.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeReleaseList extends StatelessWidget {
  final String title;
  final PageRouteInfo? route;

  const HomeReleaseList({
    super.key,
    required this.title,
    required this.route,
  });

  static const double _itemHeight = 180;

  @override
  Widget build(BuildContext context) {
    return HomePageComponent(
      text: title,
      route: route,
      sliver: Consumer<HomeReleaseListViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.status == FetchStatus.failure) {
            return const SliverToBoxAdapter(
              child: SizedBox(
                height: _itemHeight,
                child: Center(
                  child: Icon(Icons.wifi_off),
                ),
              ),
            );
          }
          if (viewModel.status != FetchStatus.success) {
            return const SliverToBoxAdapter(
              child: SizedBox(
                height: _itemHeight,
                child: Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
              ),
            );
          }
          final albums = viewModel.albums;
          if (albums.isEmpty) {
            return const SliverToBoxAdapter(
              child: SizedBox(
                height: _itemHeight,
                child: Center(
                  child: Text("No releases available"),
                ),
              ),
            );
          }
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: SizedBox(
                height: _itemHeight,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: albums.length,
                  itemExtent: _itemHeight * (4.0 / 5),
                  itemBuilder: (context, index) {
                    final a = albums[index];
                    return AspectRatio(
                      aspectRatio: 4.0 / 5,
                      child: AlbumGridCell(
                        id: a.id,
                        name: a.name,
                        extraInfo: [
                          a.displayArtist,
                          if (a.year != null) a.year.toString(),
                        ],
                        coverId: a.coverId,
                        onAddToPlaylist: () async {
                          final result = await viewModel.getAlbumSongs(a);
                          if (!context.mounted) return;
                          switch (result) {
                            case Err():
                              toastResult(context, result);
                            case Ok():
                              AddToPlaylistDialog.show(
                                  context, a.name, result.value);
                          }
                        },
                        onAddToQueue: (priority) async {
                          final result =
                              await viewModel.addToQueue(a, priority);
                          if (!context.mounted) return;
                          toastResult(context, result,
                              successMsg:
                                  "Added '${a.name}' to ${priority ? " priority" : ""} queue");
                        },
                        onTap: () {
                          context.router.push(AlbumRoute(albumId: a.id));
                        },
                        onGoToArtist: a.artists.isNotEmpty
                            ? () async {
                                final router = context.router;
                                final artistId =
                                    await ChooserDialog.chooseArtist(
                                        context, a.artists.toList());
                                if (artistId == null) return;
                                router.push(ArtistRoute(artistId: artistId));
                              }
                            : null,
                        onPlay: () async {
                          final result = await viewModel.play(a);
                          if (!context.mounted) return;
                          toastResult(context, result);
                        },
                        onShuffle: () async {
                          final result = await viewModel.play(a, shuffle: true);
                          if (!context.mounted) return;
                          toastResult(context, result);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
