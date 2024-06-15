import 'package:crossonic/repositories/api/api.dart';
import 'package:crossonic/services/audio_handler/audio_handler.dart';
import 'package:crossonic/widgets/chooser.dart';
import 'package:crossonic/widgets/cover_art.dart';
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
                      Stack(
                        children: [
                          CoverArt(
                            coverID: coverID ?? "",
                            resolution: const CoverResolution.medium(),
                            borderRadius: BorderRadius.circular(7),
                            size: constraints.maxHeight * (4 / 5),
                          ),
                          SizedBox(
                            height: constraints.maxHeight * (4 / 5),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: isFavorite
                                        ? const Icon(
                                            Icons.favorite,
                                            size: 20,
                                            color: Color.fromARGB(
                                                255, 248, 248, 248),
                                          )
                                        : null,
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Material(
                                      type: MaterialType.transparency,
                                      child: Ink(
                                        decoration: ShapeDecoration(
                                          color: Colors.black.withOpacity(0.35),
                                          shape: const CircleBorder(),
                                        ),
                                        child: SizedBox(
                                            width: 30,
                                            height: 30,
                                            child: PopupMenuButton<
                                                AlbumPopupMenuValue>(
                                              icon: const Icon(Icons.more_vert),
                                              padding: const EdgeInsets.all(0),
                                              iconColor: const Color.fromARGB(
                                                  255, 248, 248, 248),
                                              onSelected: (value) async {
                                                final audioHandler =
                                                    context.read<
                                                        CrossonicAudioHandler>();
                                                switch (value) {
                                                  case AlbumPopupMenuValue.play:
                                                    audioHandler
                                                        .playOnNextMediaChange();
                                                    audioHandler.mediaQueue
                                                        .replaceQueue(
                                                            await getSongs(
                                                                repository));
                                                  case AlbumPopupMenuValue
                                                        .addToPriorityQueue:
                                                    audioHandler.mediaQueue
                                                        .addAllToPriorityQueue(
                                                            await getSongs(
                                                                repository));
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                              SnackBar(
                                                        content: Text(
                                                            'Added "$name" to priority queue'),
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    1250),
                                                      ));
                                                    }
                                                  case AlbumPopupMenuValue
                                                        .addToQueue:
                                                    audioHandler.mediaQueue
                                                        .addAll(await getSongs(
                                                            repository));
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                              SnackBar(
                                                        content: Text(
                                                            'Added "$name" to queue'),
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    1250),
                                                      ));
                                                    }
                                                  case AlbumPopupMenuValue
                                                        .toggleFavorite:
                                                    context
                                                        .read<FavoritesCubit>()
                                                        .toggleFavorite(id);
                                                  case AlbumPopupMenuValue
                                                        .gotoArtist:
                                                    final artistID =
                                                        await ChooserDialog
                                                            .chooseArtist(
                                                                context,
                                                                artists!);
                                                    if (artistID == null) {
                                                      return;
                                                    }
                                                    if (context.mounted) {
                                                      context.push(
                                                          "/home/artist/$artistID");
                                                    }
                                                }
                                              },
                                              itemBuilder:
                                                  (BuildContext context) => [
                                                const PopupMenuItem(
                                                  value:
                                                      AlbumPopupMenuValue.play,
                                                  child: ListTile(
                                                    leading:
                                                        Icon(Icons.play_arrow),
                                                    title: Text('Play'),
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: AlbumPopupMenuValue
                                                      .addToPriorityQueue,
                                                  child: ListTile(
                                                    leading: Icon(
                                                        Icons.playlist_play),
                                                    title: Text(
                                                        'Add to priority queue'),
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: AlbumPopupMenuValue
                                                      .addToQueue,
                                                  child: ListTile(
                                                    leading: Icon(
                                                        Icons.playlist_add),
                                                    title: Text('Add to queue'),
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: AlbumPopupMenuValue
                                                      .toggleFavorite,
                                                  child: ListTile(
                                                    leading: Icon(isFavorite
                                                        ? Icons.heart_broken
                                                        : Icons.favorite),
                                                    title: Text(isFavorite
                                                        ? 'Remove from favorites'
                                                        : 'Add to favorites'),
                                                  ),
                                                ),
                                                if (artists != null)
                                                  const PopupMenuItem(
                                                    value: AlbumPopupMenuValue
                                                        .gotoArtist,
                                                    child: ListTile(
                                                      leading:
                                                          Icon(Icons.person),
                                                      title:
                                                          Text('Go to artist'),
                                                    ),
                                                  ),
                                              ],
                                            )),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
