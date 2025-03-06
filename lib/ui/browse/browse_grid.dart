import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/browse/browse_grid_button.dart';
import 'package:flutter/material.dart';

class BrowseGrid extends StatelessWidget {
  const BrowseGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: GridView.extent(
        maxCrossAxisExtent: 150,
        childAspectRatio: 4.8 / 5,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          BrowseGridButton(
            icon: Icons.people,
            text: "Artists",
            route: ArtistsRoute(),
          ),
          BrowseGridButton(
            icon: Icons.album,
            text: "Albums",
            route: AlbumsRoute(),
          ),
          BrowseGridButton(
            icon: Icons.library_music,
            text: "Songs",
            route: SongsRoute(),
          ),
          BrowseGridButton(
            icon: Icons.theater_comedy,
            text: "Genres",
            route: GenresRoute(),
          ),
        ],
      ),
    );
  }
}
