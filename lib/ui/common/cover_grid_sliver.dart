/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/ui/common/albums_grid_delegate.dart';
import 'package:flutter/material.dart';

typedef CoverGridItemBuilder =
    Widget? Function(BuildContext context, int index, double coverSize);

class CoverGridSliver extends StatefulWidget {
  final int itemCount;
  final CoverGridItemBuilder itemBuilder;

  const CoverGridSliver({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  State<CoverGridSliver> createState() => _CoverGridSliverState();
}

class _CoverGridSliverState extends State<CoverGridSliver> {
  static const _gridDelegate = AlbumsGridDelegate();

  SliverChildBuilderDelegate? _childDelegate;
  double? _childDelegateCoverSize;

  @override
  void didUpdateWidget(covariant CoverGridSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    _childDelegate = null;
  }

  SliverChildBuilderDelegate _childDelegateFor(double coverSize) {
    if (_childDelegate == null || coverSize != _childDelegateCoverSize) {
      _childDelegateCoverSize = coverSize;
      _childDelegate = SliverChildBuilderDelegate(
        (context, index) => widget.itemBuilder(context, index, coverSize),
        childCount: widget.itemCount,
        addAutomaticKeepAlives: false,
      );
    }
    return _childDelegate!;
  }

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        return SliverGrid(
          gridDelegate: _gridDelegate,
          delegate: _childDelegateFor(_gridDelegate.coverSize(constraints)),
        );
      },
    );
  }
}
