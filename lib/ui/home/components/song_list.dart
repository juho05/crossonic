import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/dialogs/add_to_playlist.dart';
import 'package:crossonic/ui/common/dialogs/chooser.dart';
import 'package:crossonic/ui/common/song_list_item.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/ui/home/components/home_page_component.dart';
import 'package:crossonic/ui/home/components/song_list_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:flutter/material.dart';

class HomeSongList extends StatelessWidget {
  final HomeSongListViewModel viewModel;

  final String title;
  final PageRouteInfo? route;

  const HomeSongList({
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
        builder: (context, child) {
          if (viewModel.status == FetchStatus.failure) {
            return Center(child: Icon(Icons.wifi_off));
          }
          if (viewModel.status != FetchStatus.success) {
            return Center(child: CircularProgressIndicator.adaptive());
          }
          final songs = viewModel.songs;
          if (songs.isEmpty) {
            return Center(
                child: Text(
              "No songs available",
            ));
          }
          return Column(
            children: songs.indexed.map(
              (e) {
                final i = e.$1;
                final s = e.$2;
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
                  onTap: () {
                    viewModel.play(i);
                  },
                );
              },
            ).toList(),
          );
        },
      ),
    );
  }
}
