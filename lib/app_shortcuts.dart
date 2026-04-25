/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class AppShortcuts extends StatelessWidget {
  final Widget child;

  const AppShortcuts({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.space, includeRepeats: false):
            const PlayPauseIntent(),
      },
      child: Actions(
        actions: {
          PlayPauseIntent: CallbackAction(
            onInvoke: (intent) async {
              final playbackManager = context.read<PlaybackManager>();
              if (playbackManager.player.playbackStatus.value ==
                  PlaybackStatus.paused) {
                await playbackManager.player.play();
              } else if (playbackManager.player.playbackStatus.value ==
                  PlaybackStatus.playing) {
                await playbackManager.player.pause();
              }
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}

class PlayPauseIntent extends Intent {
  const PlayPauseIntent();
}
