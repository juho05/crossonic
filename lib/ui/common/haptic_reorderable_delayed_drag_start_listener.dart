import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HapticReorderableDelayedDragStartListener extends StatefulWidget {
  final bool enabled;
  final int index;
  final Widget child;

  const HapticReorderableDelayedDragStartListener({
    super.key,
    this.enabled = true,
    required this.index,
    required this.child,
  });

  @override
  State<HapticReorderableDelayedDragStartListener> createState() =>
      _HapticReorderableDelayedDragStartListenerState();
}

class _HapticReorderableDelayedDragStartListenerState
    extends State<HapticReorderableDelayedDragStartListener> {
  Timer? _longPressTimer;

  void _onLongPress() {
    _pointerCancel();
    HapticFeedback.lightImpact();
  }

  void _pointerDown() {
    _longPressTimer?.cancel();
    _longPressTimer = Timer(kLongPressTimeout, _onLongPress);
  }

  void _pointerCancel() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _totalMoveOffset = Offset.zero;
  }

  Offset _totalMoveOffset = Offset.zero;

  @override
  void didUpdateWidget(
    covariant HapticReorderableDelayedDragStartListener oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled) {
      _pointerCancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }
    return ReorderableDelayedDragStartListener(
      index: widget.index,
      child: Listener(
        onPointerDown: (_) => _pointerDown(),
        onPointerCancel: (_) => _pointerCancel,
        onPointerUp: (_) => _pointerCancel,
        onPointerMove: (event) {
          if (event.down && _longPressTimer != null) {
            _totalMoveOffset += event.delta;
            if (_totalMoveOffset.distanceSquared > 50) {
              _pointerCancel();
            }
          }
        },
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    super.dispose();
  }
}
