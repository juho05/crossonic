import 'package:collection/collection.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/ui/common/clickable_list_item.dart';
import 'package:crossonic/ui/common/song_list_item.dart';
import 'package:crossonic/ui/common/song_list_sliver_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SongListSliver extends StatelessWidget {
  final List<Song> songs;
  final bool showArtist;
  final bool showAlbum;
  final bool showYear;
  final bool showBpm;
  final bool showTrackNr;
  final bool showDuration;
  final bool disableGoToAlbum;
  final bool disableGoToArtist;

  final FetchStatus? fetchStatus;

  const SongListSliver({
    super.key,
    required this.songs,
    this.fetchStatus,
    this.showArtist = true,
    this.showAlbum = false,
    this.showYear = true,
    this.showBpm = false,
    this.showTrackNr = false,
    this.showDuration = true,
    this.disableGoToAlbum = false,
    this.disableGoToArtist = false,
  });

  @override
  Widget build(BuildContext context) {
    if (fetchStatus == FetchStatus.success && songs.isEmpty) {
      return const SliverToBoxAdapter(
          child: Center(child: Text("No songs found")));
    }
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
          itemCount: (fetchStatus != null && fetchStatus != FetchStatus.success
                  ? 1
                  : 0) +
              songs.length,
          itemExtent: ClickableListItem.verticalExtent,
          itemBuilder: (context, index) {
            if (index == songs.length) {
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
            final s = songs[index];
            return SongListItem(
              key: ValueKey("${s.id}-$index"),
              song: s,
              showArtist: showArtist,
              showAlbum: showAlbum,
              showYear: showYear,
              showBpm: showBpm,
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
