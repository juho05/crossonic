/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:collection/collection.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/ui/common/clickable_list_item.dart';
import 'package:crossonic/ui/common/lazy_sliver_child.dart';
import 'package:crossonic/ui/common/song_list_item.dart';
import 'package:crossonic/ui/common/song_list_sliver_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SongListSliver extends StatefulWidget {
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
  State<SongListSliver> createState() => _SongListSliverState();
}

class _SongListSliverState extends State<SongListSliver> {
  static const _extent = ClickableListItem.verticalExtent;

  final _budget = ChildCreationBudget();
  final _rows = <int, LazySliverChild>{};
  SliverChildBuilderDelegate? _delegate;
  int _trackDigits = 1;

  @override
  void didUpdateWidget(covariant SongListSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    _delegate = null;
  }

  Widget _rowFor(int index, SongListSliverViewModel viewModel) {
    final songs = widget.songs;
    final s = songs[index];
    final cacheKey = (
      songs,
      s,
      index,
      _trackDigits,
      widget.showArtist,
      widget.showAlbum,
      widget.showYear,
      widget.showBpm,
      widget.showTrackNr,
      widget.showDuration,
      widget.disableGoToAlbum,
      widget.disableGoToArtist,
    );
    var row = _rows[index];
    if (row == null || row.cacheKey != cacheKey) {
      row = LazySliverChild(
        key: ValueKey("${s.id}-$index"),
        index: index,
        budget: _budget,
        cacheKey: cacheKey,
        builder: (context) => SongListItem(
          song: s,
          showArtist: widget.showArtist,
          showAlbum: widget.showAlbum,
          showYear: widget.showYear,
          showBpm: widget.showBpm,
          showTrackNr: widget.showTrackNr,
          fallbackTrackNr: index + 1,
          trackDigits: _trackDigits,
          showDuration: widget.showDuration,
          disableGoToAlbum: widget.disableGoToAlbum,
          disableGoToArtist: widget.disableGoToArtist,
          onTap: (ctrlPressed) {
            viewModel.play(songs, index, ctrlPressed);
          },
        ),
      );
      _rows[index] = row;
    }
    return row;
  }

  SliverChildBuilderDelegate _delegateFor(SongListSliverViewModel viewModel) {
    return _delegate ??= SliverChildBuilderDelegate(
      (context, index) {
        if (index == widget.songs.length) {
          return switch (widget.fetchStatus) {
            FetchStatus.success => null,
            FetchStatus.failure => const Center(child: Icon(Icons.wifi_off)),
            _ => const Center(child: CircularProgressIndicator.adaptive()),
          };
        }
        return _rowFor(index, viewModel);
      },
      childCount:
          (widget.fetchStatus != null &&
                  widget.fetchStatus != FetchStatus.success
              ? 1
              : 0) +
          widget.songs.length,
      addAutomaticKeepAlives: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final songs = widget.songs;
    if (widget.fetchStatus == FetchStatus.success && songs.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: Text("No songs found")),
      );
    }
    _trackDigits = songs.isNotEmpty
        ? songs.mapIndexed((i, s) => s.trackNr ?? i + 1).max.toString().length
        : 1;
    return Provider(
      create: (context) =>
          SongListSliverViewModel(playbackManager: context.read()),
      builder: (context, _) {
        final viewModel = context.read<SongListSliverViewModel>();
        return SliverLayoutBuilder(
          builder: (context, constraints) {
            _budget.visible = SliverVisibleRange(
              (constraints.scrollOffset / _extent).floor(),
              ((constraints.scrollOffset + constraints.remainingPaintExtent) /
                      _extent)
                  .ceil(),
            );
            return SliverFixedExtentList(
              itemExtent: _extent,
              delegate: _delegateFor(viewModel),
            );
          },
        );
      },
    );
  }
}
