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
import 'package:crossonic/ui/common/lazy_sliver_child.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:flutter/material.dart';

class AlbumGridSliver extends StatefulWidget {
  final List<Album> albums;
  final FetchStatus fetchStatus;

  const AlbumGridSliver({
    super.key,
    required this.albums,
    required this.fetchStatus,
  });

  @override
  State<AlbumGridSliver> createState() => _AlbumGridSliverState();
}

class _AlbumGridSliverState extends State<AlbumGridSliver> {
  // Reusing the identical widget for an album lets the element tree skip the
  // cell entirely when the grid rebuilds, e.g. when a page load appends
  // albums while a fling is in progress.
  final _cells = Expando<LazySliverChild>();
  final _budget = ChildCreationBudget();

  Widget _cellFor(Album album, int index, CoverGridGeometry geometry) {
    _budget.visible = geometry.visible;
    var cell = _cells[album];
    if (cell == null ||
        cell.index != index ||
        cell.cacheKey != (album, geometry.coverSize)) {
      cell = LazySliverChild(
        key: ValueKey(album.id),
        index: index,
        budget: _budget,
        cacheKey: (album, geometry.coverSize),
        builder: (context) =>
            AlbumGridCell(album: album, coverSize: geometry.coverSize),
      );
      _cells[album] = cell;
    }
    return cell;
  }

  @override
  Widget build(BuildContext context) {
    final albums = widget.albums;
    final fetchStatus = widget.fetchStatus;
    if (fetchStatus == FetchStatus.success && albums.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: Text("No releases found")),
      );
    }
    return SliverPadding(
      padding: const EdgeInsetsGeometry.symmetric(horizontal: 4),
      sliver: CoverGridSliver(
        itemCount: (fetchStatus == FetchStatus.success ? 0 : 1) + albums.length,
        itemBuilder: (context, index, geometry) {
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
          return _cellFor(albums[index], index, geometry);
        },
      ),
    );
  }
}
