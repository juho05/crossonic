/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/auto_hide_fab.dart';
import 'package:crossonic/ui/main/now_playing/now_playing_viewmodel.dart';
import 'package:flutter/material.dart';

class QueueFab extends StatelessWidget {
  final NowPlayingViewModel _nowPlayingViewModel;
  final bool _hide;

  const QueueFab({
    super.key,
    required NowPlayingViewModel nowPlayingViewModel,
    bool hide = false,
  }) : _nowPlayingViewModel = nowPlayingViewModel,
       _hide = hide;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _nowPlayingViewModel,
      builder: (context, child) {
        if (_hide ||
            _nowPlayingViewModel.playbackStatus != PlaybackStatus.stopped ||
            !_nowPlayingViewModel.hasNamedQueues) {
          return const SizedBox.shrink();
        }
        return AutoHideFAB(
          onPressed: () {
            context.router.push(const SelectQueueRoute());
          },
          tooltip: "Select queue",
          child: const Icon(Icons.queue_music),
        );
      },
    );
  }
}
