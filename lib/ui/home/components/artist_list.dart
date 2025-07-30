import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/artist_grid_cell.dart';
import 'package:crossonic/ui/common/dialogs/add_to_playlist.dart';
import 'package:crossonic/ui/common/dialogs/chooser.dart';
import 'package:crossonic/ui/home/components/artist_list_viewmodel.dart';
import 'package:crossonic/ui/home/components/home_page_component.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeArtistList extends StatelessWidget {
  final String title;
  final PageRouteInfo? route;

  const HomeArtistList({
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
      sliver: Consumer<HomeArtistListViewModel>(
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
          final artists = viewModel.artists;
          if (artists.isEmpty) {
            return const SliverToBoxAdapter(
              child: SizedBox(
                height: _itemHeight,
                child: Center(
                  child: Text("No artists available"),
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
                  itemCount: artists.length,
                  itemExtent: _itemHeight * (4.0 / 5),
                  itemBuilder: (context, index) {
                    final a = artists[index];
                    return AspectRatio(
                      aspectRatio: 4.0 / 5,
                      child: ArtistGridCell(
                        id: a.id,
                        name: a.name,
                        extraInfo: [
                          if (a.albumCount != null) "Releases: ${a.albumCount}"
                        ],
                        coverId: a.coverId,
                        onAddToPlaylist: () async {
                          final result = await viewModel.getArtistSongs(a);
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
                          context.router.push(ArtistRoute(artistId: a.id));
                        },
                        onPlay: () async {
                          final result = await viewModel.play(a);
                          if (!context.mounted) return;
                          toastResult(context, result);
                        },
                        onShuffle: () async {
                          final option = await ChooserDialog.choose(
                              context, "Shuffle", ["Releases", "Songs"]);
                          if (option == null) return;
                          final result = await viewModel.play(a,
                              shuffleAlbums: option == 0,
                              shuffleSongs: option == 1);
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
