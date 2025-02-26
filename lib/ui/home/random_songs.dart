import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/song_list_item.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/ui/home/random_songs_viewmodel.dart';
import 'package:crossonic/ui/home/widgets/home_page_component.dart';
import 'package:flutter/material.dart';

class RandomSongs extends StatelessWidget {
  final RandomSongsViewModel viewModel;

  const RandomSongs({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return HomePageComponent(
      text: "Random songs",
      route: ArtistRoute(), // TODO change to correct route
      child: ListenableBuilder(
        listenable: viewModel.load,
        builder: (context, child) {
          if (viewModel.load.error) {
            return Center(child: Icon(Icons.wifi_off));
          }
          if (viewModel.load.running || !viewModel.load.completed) {
            return Center(child: CircularProgressIndicator.adaptive());
          }
          final songs = viewModel.load.result!.tryValue!;
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
                    // TODO
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
                  onGoToArtist: () {
                    // TODO
                  },
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
