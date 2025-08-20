import 'package:crossonic/data/repositories/subsonic/models/artist.dart';
import 'package:crossonic/ui/common/artist_list_item.dart';
import 'package:crossonic/ui/common/clickable_list_item.dart';
import 'package:flutter/cupertino.dart';

class ArtistListSliver extends StatelessWidget {
  final List<Artist> artists;
  final bool showAlbumCount;

  const ArtistListSliver({
    super.key,
    required this.artists,
    this.showAlbumCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return SliverFixedExtentList.builder(
      itemCount: artists.length,
      itemExtent: ClickableListItem.verticalExtent,
      itemBuilder: (context, index) {
        final a = artists[index];
        return ArtistListItem(
          artist: a,
          showAlbumCount: showAlbumCount,
        );
      },
    );
  }
}
