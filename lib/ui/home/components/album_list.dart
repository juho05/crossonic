import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/album_grid_cell.dart';
import 'package:crossonic/ui/common/dialogs/chooser.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/ui/home/components/album_list_viewmodel.dart';
import 'package:crossonic/ui/home/components/home_page_component.dart';
import 'package:crossonic/utils/exceptions.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class HomeAlbumList extends StatelessWidget {
  final HomeAlbumListViewModel viewModel;
  final String title;
  final PageRouteInfo? route;

  const HomeAlbumList({
    super.key,
    required this.viewModel,
    required this.title,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return HomePageComponent(
      text: title,
      route: route,
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          if (viewModel.status == FetchStatus.failure) {
            return Center(child: Icon(Icons.wifi_off));
          }
          if (viewModel.status != FetchStatus.success) {
            return Center(child: CircularProgressIndicator.adaptive());
          }
          final albums = viewModel.albums;
          if (albums.isEmpty) {
            return Center(
                child: Text(
              "No albums available",
            ));
          }
          return Padding(
            padding: const EdgeInsets.only(left: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 2,
                children: List<Widget>.generate(
                  albums.length,
                  (index) {
                    final a = albums[index];
                    return SizedBox(
                      height: 190,
                      child: AspectRatio(
                        aspectRatio: 4.0 / 5,
                        child: AlbumGridCell(
                          id: a.id,
                          name: a.name,
                          extraInfo: [
                            a.displayArtist,
                            if (a.year != null) a.year.toString(),
                          ],
                          coverId: a.coverId,
                          onAddToPlaylist: () {
                            // TODO
                          },
                          onAddToQueue: (priority) async {
                            final result =
                                await viewModel.addToQueue(a, priority);
                            if (!context.mounted) return;
                            if (result is Err) {
                              switch (result.error) {
                                case ConnectionException():
                                  Toast.show(
                                      context, "Failed to contact server");
                                default:
                                  Toast.show(
                                      context, "An unexpected error occured");
                              }
                            } else {
                              Toast.show(context,
                                  "Added '${a.name}' to ${priority ? " priority" : ""} queue");
                            }
                          },
                          onTap: () {
                            context.router.push(AlbumRoute(albumId: a.id));
                          },
                          onGoToArtist: () async {
                            final router = context.router;
                            final artistId = await ChooserDialog.chooseArtist(
                                context, a.artists.toList());
                            if (artistId == null) return;
                            router.push(ArtistRoute(artistId: artistId));
                          },
                          onPlay: () async {
                            final result = await viewModel.play(a);
                            if (result is Err && context.mounted) {
                              switch (result.error) {
                                case ConnectionException():
                                  Toast.show(
                                      context, "Failed to contact server");
                                default:
                                  Toast.show(
                                      context, "An unexpected error occured");
                              }
                            }
                          },
                          onShuffle: () async {
                            final result =
                                await viewModel.play(a, shuffle: true);
                            if (result is Err && context.mounted) {
                              switch (result.error) {
                                case ConnectionException():
                                  Toast.show(
                                      context, "Failed to contact server");
                                default:
                                  Toast.show(
                                      context, "An unexpected error occured");
                              }
                            }
                          },
                        ),
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
