import 'package:collection/collection.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/ui/common/clickable_list_item.dart';
import 'package:crossonic/ui/common/song_list_item.dart';
import 'package:crossonic/ui/common/song_list_sliver_viewmodel.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class SongListSliver extends StatelessWidget {
  final List<Song> songs;
  final bool showArtist;
  final bool showAlbum;
  final bool showYear;
  final bool showTrackNr;
  final bool showDuration;
  final bool disableGoToAlbum;
  final bool disableGoToArtist;

  const SongListSliver({
    super.key,
    required this.songs,
    this.showArtist = true,
    this.showAlbum = false,
    this.showYear = true,
    this.showTrackNr = false,
    this.showDuration = true,
    this.disableGoToAlbum = false,
    this.disableGoToArtist = false,
  });

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (context) =>
          SongListSliverViewModel(audioHandler: context.read()),
      builder: (context, _) {
        final viewModel = context.read<SongListSliverViewModel>();
        final trackDigits = songs.isNotEmpty
            ? songs
                .mapIndexed((i, s) => s.trackNr ?? i + 1)
                .max
                .toString()
                .length
            : 1;
        return SliverFixedExtentList.builder(
          itemCount: songs.length,
          itemExtent: ClickableListItem.verticalExtent,
          itemBuilder: (context, index) {
            final s = songs[index];
            return SongListItem(
              song: s,
              showArtist: showArtist,
              showAlbum: showAlbum,
              showYear: showYear,
              showTrackNr: showTrackNr,
              fallbackTrackNr: index + 1,
              trackDigits: trackDigits,
              showDuration: showDuration,
              disableGoToAlbum: disableGoToAlbum,
              disableGoToArtist: disableGoToArtist,
              onTap: (ctrlPressed) {
                viewModel.play(songs, index, ctrlPressed);
              },
            );
          },
        );
      },
    );
  }
}
