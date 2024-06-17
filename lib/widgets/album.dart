import 'package:crossonic/repositories/api/api.dart';
import 'package:crossonic/widgets/cover_art.dart';
import 'package:crossonic/widgets/large_cover.dart';
import 'package:crossonic/widgets/state/favorites_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

enum AlbumPopupMenuValue {
  play,
  addToPriorityQueue,
  addToQueue,
  toggleFavorite,
  gotoArtist
}

class Album extends StatelessWidget {
  final String id;
  final String name;
  final String extraInfo;
  final String? coverID;
  final List<ArtistIDName>? artists;
  const Album({
    super.key,
    required this.id,
    required this.name,
    required this.extraInfo,
    this.artists,
    this.coverID,
  });

  Future<List<Media>> getSongs(APIRepository repository) async {
    final album = await repository.getAlbum(id);
    return album.song ?? <Media>[];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textTheme = Theme.of(context).textTheme;
        final repository = context.read<APIRepository>();
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              context.push("/home/album/$id");
            },
            child: BlocBuilder<FavoritesCubit, FavoritesState>(
              buildWhen: (previous, current) => current.changedId == id,
              builder: (context, state) {
                final isFavorite = state.favorites.contains(id);
                return SizedBox(
                  width: constraints.maxHeight * (4 / 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CoverArtWithMenu(
                        id: id,
                        name: name,
                        size: constraints.maxHeight * (4 / 5),
                        resolution: const CoverResolution.medium(),
                        enablePlay: true,
                        enableShuffle: true,
                        enableQueue: true,
                        artists: artists,
                        coverID: id,
                        isFavorite: isFavorite,
                        getSongs: () async => await getSongs(repository),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w400,
                          fontSize: constraints.maxHeight * 0.07,
                        ),
                      ),
                      Text(
                        extraInfo,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w300,
                          fontSize: constraints.maxHeight * 0.06,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
