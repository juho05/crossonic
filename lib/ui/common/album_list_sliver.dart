/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/ui/common/album_list_item.dart';
import 'package:crossonic/ui/common/clickable_list_item.dart';
import 'package:flutter/cupertino.dart';

class AlbumListSliver extends StatelessWidget {
  final List<Album> albums;
  final bool showArtist;
  final bool showYear;
  final bool showSongCount;
  final bool disableGoToArtist;

  const AlbumListSliver({
    super.key,
    required this.albums,
    this.showArtist = true,
    this.showYear = true,
    this.showSongCount = true,
    this.disableGoToArtist = false,
  });

  @override
  Widget build(BuildContext context) {
    return SliverFixedExtentList.builder(
      itemCount: albums.length,
      itemExtent: ClickableListItem.verticalExtent,
      itemBuilder: (context, index) {
        final a = albums[index];
        return AlbumListItem(
          album: a,
          showArtist: showArtist,
          showYear: showYear,
          showSongCount: showSongCount,
          disableGoToArtist: disableGoToArtist,
        );
      },
    );
  }
}
