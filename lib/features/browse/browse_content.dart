import 'package:crossonic/features/browse/state/browse_bloc.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BrowseContent extends StatelessWidget {
  final BrowseType _type;
  const BrowseContent({super.key, required type}) : _type = type;

  @override
  Widget build(BuildContext context) {
    switch (_type) {
      case BrowseType.song:
        return const BrowseContentSongs();
      case BrowseType.album:
        return const BrowseContentAlbums();
      case BrowseType.artist:
        return const BrowseContentArtists();
    }
  }
}

class BrowseContentSongs extends StatelessWidget {
  const BrowseContentSongs({super.key});

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
        children: const [
          //BrowseContentGridCell(
          //  icon: Icons.favorite_border,
          //  targetURL: "/browse/songs/favorite",
          //  text: "Favorite Songs",
          //),
          BrowseContentGridCell(
            icon: Icons.library_music_outlined,
            targetURL: "/browse/songs/none",
            text: "All Songs",
          ),
          BrowseContentGridCell(
            icon: Icons.shuffle,
            targetURL: "/browse/songs/random",
            text: "Random Songs",
          ),
        ],
      ),
    );
  }
}

class BrowseContentAlbums extends StatelessWidget {
  const BrowseContentAlbums({super.key});

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
        children: const [
          //BrowseContentGridCell(
          //  icon: Icons.favorite_border,
          //  targetURL: "/browse/albums/favorite",
          //  text: "Favorite Albums",
          //),
          BrowseContentGridCell(
            icon: Icons.album_outlined,
            targetURL: "/browse/albums/alphabetical",
            text: "All Albums",
          ),
          BrowseContentGridCell(
            icon: Icons.shuffle,
            targetURL: "/browse/albums/random",
            text: "Random Albums",
          ),
        ],
      ),
    );
  }
}

class BrowseContentArtists extends StatelessWidget {
  const BrowseContentArtists({super.key});

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
        children: const [
          //BrowseContentGridCell(
          //  icon: Icons.favorite_border,
          //  targetURL: "/browse/artists/favorite",
          //  text: "Favorite Artists",
          //),
          //BrowseContentGridCell(
          //  icon: Icons.person_outline,
          //  targetURL: "/browse/artists/alphabetical",
          //  text: "All Artists",
          //),
          //BrowseContentGridCell(
          //  icon: Icons.shuffle,
          //  targetURL: "/browse/artists/random",
          //  text: "Random Artists",
          //)
        ],
      ),
    );
  }
}

class BrowseContentGridCell extends StatelessWidget {
  final IconData icon;
  final String text;
  final String targetURL;

  const BrowseContentGridCell(
      {super.key,
      required this.icon,
      required this.text,
      required this.targetURL});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textTheme = Theme.of(context).textTheme;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              context.push(targetURL);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: Theme.of(context).colorScheme.surfaceContainer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Icon(icon, size: constraints.maxHeight * 0.5),
                    const SizedBox(height: 8),
                    Text(
                      text,
                      style: textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: constraints.maxHeight * 0.1,
                      ),
                      textAlign: TextAlign.center,
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
