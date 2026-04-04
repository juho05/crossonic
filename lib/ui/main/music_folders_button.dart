/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/subsonic/music_folders_repository.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MusicFoldersButton extends StatelessWidget {
  const MusicFoldersButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: context.read<AuthRepository>().serverFeatures,
      builder: (context, _) {
        if (!context.read<SubsonicRepository>().supports.musicFolders) {
          return const SizedBox.shrink();
        }
        final musicFoldersRepo = context.read<MusicFoldersRepository>();
        return ListenableBuilder(
          listenable: musicFoldersRepo,
          builder: (context, _) {
            final filtersActive = musicFoldersRepo.selected.isNotEmpty;
            return IconButton(
              icon: filtersActive
                  ? const Icon(Icons.folder_copy)
                  : const Icon(Icons.folder_copy_outlined),
              onPressed: () {
                context.router.push(const MusicFoldersRoute());
              },
            );
          },
        );
      },
    );
  }
}
