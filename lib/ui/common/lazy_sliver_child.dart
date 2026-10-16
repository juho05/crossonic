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

class _LazySliverChildState extends State<LazySliverChild>
    with _BudgetedBuild {
  Widget? _child;
  Object? _childKey;

  @override
  Widget build(BuildContext context) {
    if (_child == null || _childKey != widget.cacheKey) {
      _childKey = widget.cacheKey;
      _child = LayoutBuilder(
        builder: (context, _) => _buildBudgeted(
          widget.budget,
          widget.index,
          () => _LazySliverScope(
            budget: widget.budget,
            index: widget.index,
            child: widget.builder(context),
          ),
        ),
      );
    }
    return _child!;
  }

  @override
  void _retry() => setState(() => _child = null);
}

class _LazySliverScope extends InheritedWidget {
  final ChildCreationBudget budget;
  final int index;

  const _LazySliverScope({
    required this.budget,
    required this.index,
    required super.child,
  });

  @override
  bool updateShouldNotify(_LazySliverScope oldWidget) => false;
}

// Defers part of a LazySliverChild to a later frame once the budget is used
// up, so an expensive child is spread over several frames instead of
// overrunning a single one. Builds immediately outside of a LazySliverChild.
class LazySliverStage extends StatefulWidget {
  final WidgetBuilder builder;
  final Widget placeholder;

  const LazySliverStage({
    super.key,
    required this.builder,
    this.placeholder = const SizedBox(),
  });

  @override
  State<LazySliverStage> createState() => _LazySliverStageState();
}

class _LazySliverStageState extends State<LazySliverStage>
    with _BudgetedBuild {
  @override
  Widget build(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<_LazySliverScope>();
    if (scope == null) return widget.builder(context);
    return LayoutBuilder(
      builder: (context, _) => _buildBudgeted(
        scope.budget,
        scope.index,
        () => widget.builder(context),
        widget.placeholder,
      ),
    );
  }

  @override
  void _retry() => setState(() {});
}

// The budget is checked in a layout callback, because build runs ahead of
// layout and would not account for the layout cost of earlier children.
mixin _BudgetedBuild<T extends StatefulWidget> on State<T> {
  bool _created = false;
  bool _retryScheduled = false;

  Widget _buildBudgeted(
    ChildCreationBudget budget,
    int index,
    Widget Function() build, [
    Widget placeholder = const SizedBox(),
  ]) {
    if (!_created) {
      if (!budget.mayCreate(index)) {
        _scheduleRetry();
        return placeholder;
      }
      _created = true;
    }
    return build();
  }

  void _retry();

  void _scheduleRetry() {
    if (_retryScheduled) return;
    _retryScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _retryScheduled = false;
      if (mounted) _retry();
    });
  }
}
