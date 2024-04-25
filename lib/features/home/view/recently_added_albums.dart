import 'package:crossonic/features/home/view/state/recently_added_albums_cubit.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/widgets/album.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RecentlyAddedAlbums extends StatelessWidget {
  const RecentlyAddedAlbums({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecentlyAddedAlbumsCubit, RecentlyAddedAlbumsState>(
      builder: (context, state) {
        return SizedBox(
            height: 180,
            child: switch (state.status) {
              FetchStatus.initial ||
              FetchStatus.loading =>
                const Center(child: CircularProgressIndicator.adaptive()),
              FetchStatus.failure => const Center(child: Icon(Icons.wifi_off)),
              FetchStatus.success ||
              FetchStatus.loadingMore =>
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List<Widget>.generate(
                        state.albums.length,
                        (i) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              child: Album(
                                id: state.albums[i].id,
                                name: state.albums[i].name,
                                extraInfo:
                                    "${state.albums[i].artist}${state.albums[i].year != null ? " • ${state.albums[i].year}" : ""}",
                                coverID: state.albums[i].coverID ?? "",
                              ),
                            )),
                  ),
                )
            });
      },
    );
  }
}
