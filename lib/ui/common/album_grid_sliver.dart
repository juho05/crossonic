import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/ui/common/album_grid_cell.dart';
import 'package:crossonic/ui/common/albums_grid_delegate.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:flutter/material.dart';

class AlbumGridSliver extends StatelessWidget {
  final List<Album> albums;
  final FetchStatus fetchStatus;

  const AlbumGridSliver(
      {super.key, required this.albums, required this.fetchStatus});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsetsGeometry.symmetric(horizontal: 4),
      sliver: SliverGrid(
        gridDelegate: AlbumsGridDelegate(),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index > albums.length) {
              return null;
            }
            if (index == albums.length) {
              return switch (fetchStatus) {
                FetchStatus.success => null,
                FetchStatus.failure => const Center(
                    child: Icon(Icons.wifi_off),
                  ),
                _ => const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
              };
            }
            final a = albums[index];
            return AlbumGridCell(
              album: a,
            );
          },
          childCount:
              (fetchStatus == FetchStatus.success ? 0 : 1) + albums.length,
        ),
      ),
    );
  }
}
