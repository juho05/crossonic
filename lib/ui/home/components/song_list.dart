import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/clickable_list_item.dart';
import 'package:crossonic/ui/common/dialogs/add_to_playlist.dart';
import 'package:crossonic/ui/common/dialogs/chooser.dart';
import 'package:crossonic/ui/common/song_list_item.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/ui/home/components/home_page_component.dart';
import 'package:crossonic/ui/home/components/song_list_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeSongList extends StatelessWidget {
  final String title;
  final PageRouteInfo? route;

  const HomeSongList({
    super.key,
    required this.title,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return HomePageComponent(
      text: title,
      route: route,
      sliver: Consumer<HomeSongListViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.status == FetchStatus.failure) {
            return const SliverToBoxAdapter(
              child: SizedBox(
                height: ClickableListItem.verticalExtent * 10,
                child: Center(
                  child: Icon(Icons.wifi_off),
                ),
              ),
            );
          }
          if (viewModel.status != FetchStatus.success) {
            return const SliverToBoxAdapter(
              child: SizedBox(
                height: ClickableListItem.verticalExtent * 10,
                child: Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
              ),
            );
          }
          final songs = viewModel.songs;
          if (songs.isEmpty) {
            return const SliverToBoxAdapter(
              child: SizedBox(
                height: ClickableListItem.verticalExtent,
                child: Center(
                  child: Text("No songs available"),
                ),
              ),
            );
          }
          return SliverFixedExtentList.builder(
            itemCount: songs.length,
            itemExtent: ClickableListItem.verticalExtent,
            itemBuilder: (context, index) {
              final s = songs[index];
              return SongListItem(
                id: s.id,
                title: s.title,
                artist: s.displayArtist,
                coverId: s.coverId,
                duration: s.duration,
                year: s.year,
                onAddToPlaylist: () {
                  AddToPlaylistDialog.show(context, s.title, [s]);
                },
                onAddToQueue: (prio) {
                  viewModel.addSongToQueue(s, prio);
                  Toast.show(context,
                      "Added '${s.title}' to ${prio ? "priority " : ""}queue!");
                },
                onGoToAlbum: s.album != null
                    ? () {
                        context.router.push(AlbumRoute(albumId: s.album!.id));
                      }
                    : null,
                onGoToArtist: s.artists.isNotEmpty
                    ? () async {
                        final router = context.router;
                        final artistId = await ChooserDialog.chooseArtist(
                            context, s.artists.toList());
                        if (artistId == null) return;
                        router.push(ArtistRoute(artistId: artistId));
                      }
                    : null,
                onTap: (ctrlPressed) {
                  viewModel.play(index, ctrlPressed);
                },
              );
            },
          );
        },
      ),
    );
  }
}
