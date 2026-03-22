/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

class AutoHideFAB extends StatelessWidget {
  static const _duration = Duration(milliseconds: 100);

  final void Function() onPressed;
  final String? tooltip;
  final Widget child;

  const AutoHideFAB({
    super.key,
    required this.onPressed,
    this.tooltip,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AutoHideFABState>(
      builder: (context, state, _) => AnimatedSlide(
        duration: _duration,
        offset: state.visible ? Offset.zero : const Offset(0, 1),
        child: AnimatedOpacity(
          duration: _duration,
          opacity: state.visible ? 1 : 0,
          child: FloatingActionButton(
            onPressed: onPressed,
            heroTag: null,
            tooltip: tooltip,
            child: child,
          ),
        ),
      ),
    );
  }
}

class AutoHideFABDetector extends StatefulWidget {
  final Widget child;

  const AutoHideFABDetector({super.key, required this.child});

  @override
  State<AutoHideFABDetector> createState() => _AutoHideFABDetectorState();
}

class _AutoHideFABDetectorState extends State<AutoHideFABDetector> {
  final AutoHideFABState viewModel = AutoHideFABState();

  ScrollDirection? _lastDirection;
  Timer? _onScrollChangedDebounce;
  void _onScrollChanged(ScrollDirection direction) {
    if (direction == _lastDirection) return;
    _lastDirection = direction;
    _onScrollChangedDebounce?.cancel();
    _onScrollChangedDebounce = Timer(const Duration(milliseconds: 50), () {
      if (direction == ScrollDirection.reverse) {
        viewModel.visible = false;
      } else {
        viewModel.visible = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      builder: (context, _) {
        return Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              if (event.scrollDelta.dy == 0) return;
              _onScrollChanged(
                event.scrollDelta.dy < 0
                    ? ScrollDirection.forward
                    : ScrollDirection.reverse,
              );
            }
          },
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.kind == PointerDeviceKind.mouse ||
                  details.delta.dy.abs() < 0.5) {
                return;
              }
              _onScrollChanged(
                details.delta.dy > 0
                    ? ScrollDirection.forward
                    : ScrollDirection.reverse,
              );
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is! UserScrollNotification) return false;
                if (notification.metrics.axis != Axis.vertical) return false;
                if (notification.direction == ScrollDirection.idle) {
                  return false;
                }
                _onScrollChanged(notification.direction);
                return false;
              },
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

class AutoHideFABState extends ChangeNotifier {
  bool _visible = true;
  bool get visible => _visible;
  set visible(bool visible) {
    _visible = visible;
    notifyListeners();
  }
}
