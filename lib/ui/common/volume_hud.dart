/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/ui/common/volume_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VolumeHud extends StatefulWidget {
  const VolumeHud({super.key});

  @override
  State<VolumeHud> createState() => _VolumeHudState();
}

class _VolumeHudState extends State<VolumeHud> {
  static const Duration _dismissDelay = Duration(milliseconds: 1500);

  StreamSubscription<void>? _subscription;
  Timer? _dismissTimer;
  bool _visible = false;

  late final OverlayEntry _entry;

  @override
  void initState() {
    super.initState();
    _entry = OverlayEntry(builder: _buildHud);
    _subscription = context.read<PlaybackManager>().volumeKeyEvents.listen((_) {
      _visible = true;
      _entry.markNeedsBuild();
      _resetTimer();
    });
  }

  void _resetTimer() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(_dismissDelay, () {
      _visible = false;
      _entry.markNeedsBuild();
    });
  }

  Widget _buildHud(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: !_visible
                  ? const SizedBox.shrink()
                  : Listener(
                      onPointerDown: (_) => _resetTimer(),
                      onPointerMove: (_) => _resetTimer(),
                      onPointerSignal: (_) => _resetTimer(),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: VolumeSlider(
                              constraints: BoxConstraints.tightFor(width: 220),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(initialEntries: [_entry]);
  }
}
