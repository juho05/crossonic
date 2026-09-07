/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/ui/common/album_grid_cell.dart';
import 'package:crossonic/ui/common/cover_grid_sliver.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:flutter/material.dart';

class AlbumGridSliver extends StatelessWidget {
  final List<Album> albums;
  final FetchStatus fetchStatus;

  const AlbumGridSliver({
    super.key,
    required this.albums,
    required this.fetchStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (fetchStatus == FetchStatus.success && albums.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: Text("No releases found")),
      );
    }
    return SliverPadding(
      padding: const EdgeInsetsGeometry.symmetric(horizontal: 4),
      sliver: CoverGridSliver(
        itemCount: (fetchStatus == FetchStatus.success ? 0 : 1) + albums.length,
        itemBuilder: (context, index, coverSize) {
          if (index > albums.length) {
            return null;
          }
          if (index == albums.length) {
            return switch (fetchStatus) {
              FetchStatus.success => null,
              FetchStatus.failure => const Center(child: Icon(Icons.wifi_off)),
              _ => const Center(child: CircularProgressIndicator.adaptive()),
            };
          }
          final a = albums[index];
          return AlbumGridCell(
            album: a,
            key: ValueKey(a.id),
            coverSize: coverSize,
          );
        },
      ),
    );
  }
}
