/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

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
        return ArtistListItem(artist: a, showAlbumCount: showAlbumCount);
      },
    );
  }
}
