/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:developer' show Timeline;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/scheduler.dart';

class SliverVisibleRange {
  final int first;
  final int last;

  const SliverVisibleRange(this.first, this.last);

  bool contains(int index) => index >= first && index <= last;
}

// Creating a whole row of list children in one frame overruns the frame
// budget on phones. Children outside the viewport are therefore created ahead
// of time in the cache area, and once the children created in a frame have
// taken this long, the rest waits for the next frame. Slivers lay out each
// new child right after building it, so the elapsed time covers both.
class ChildCreationBudget {
  static const _budgetUs = 2500;

  SliverVisibleRange visible = const SliverVisibleRange(0, -1);
  Duration? _frame;
  int _firstCreationUs = 0;

  bool mayCreate(int index) {
    if (visible.contains(index)) return true;
    final scheduler = SchedulerBinding.instance;
    if (scheduler.schedulerPhase == SchedulerPhase.idle) return true;
    final frame = scheduler.currentFrameTimeStamp;
    final now = Timeline.now;
    if (frame != _frame) {
      _frame = frame;
      _firstCreationUs = now;
      return true;
    }
    return now - _firstCreationUs < _budgetUs;
  }
}

// Stays empty until the budget grants a child for the frame, then keeps the
// built child so later rebuilds are skipped by the element tree as long as
// cacheKey is unchanged.
class LazySliverChild extends StatefulWidget {
  final int index;
  final ChildCreationBudget budget;
  final Object cacheKey;
  final WidgetBuilder builder;

  const LazySliverChild({
    super.key,
    required this.index,
    required this.budget,
    required this.cacheKey,
    required this.builder,
  });

  @override
  State<LazySliverChild> createState() => _LazySliverChildState();
}

class _LazySliverChildState extends State<LazySliverChild> {
  Widget? _child;
  Object? _childKey;
  bool _retryScheduled = false;

  @override
  Widget build(BuildContext context) {
    final child = _child;
    if (child != null && _childKey == widget.cacheKey) {
      return child;
    }
    if (child == null && !widget.budget.mayCreate(widget.index)) {
      _scheduleRetry();
      return const SizedBox();
    }
    _childKey = widget.cacheKey;
    return _child = widget.builder(context);
  }

  void _scheduleRetry() {
    if (_retryScheduled) return;
    _retryScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _retryScheduled = false;
      if (mounted) setState(() {});
    });
  }
}
