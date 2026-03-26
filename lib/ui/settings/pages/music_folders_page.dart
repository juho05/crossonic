/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:auto_route/annotations.dart';
import 'package:crossonic/ui/settings/pages/music_folders_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class MusicFoldersPage extends StatelessWidget {
  const MusicFoldersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          MusicFoldersViewModel(subsonic: context.read(), repo: context.read()),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text("Libraries")),
          body: SafeArea(
            child: Consumer<MusicFoldersViewModel>(
              builder: (context, viewModel, _) {
                if (viewModel.status == FetchStatus.failure) {
                  return const Center(child: Icon(Icons.wifi_off));
                }
                if (viewModel.status != FetchStatus.success) {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(),
                  );
                }
                if (!viewModel.supportsMultiSelect) {
                  return RadioGroup<int>(
                    groupValue:
                        viewModel.selected.firstOrNull ??
                        MusicFoldersViewModel.ALL_ID,
                    onChanged: (value) {
                      viewModel.select(value ?? MusicFoldersViewModel.ALL_ID);
                    },
                    child: ListView.builder(
                      itemCount: viewModel.musicFolders.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return const Column(
                            children: [
                              RadioListTile.adaptive(
                                title: Text("All"),
                                value: MusicFoldersViewModel.ALL_ID,
                              ),
                              Divider(),
                            ],
                          );
                        }
                        final folder = viewModel.musicFolders[index - 1];
                        return RadioListTile.adaptive(
                          title: Text(folder.name),
                          value: folder.id,
                        );
                      },
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: viewModel.musicFolders.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Column(
                        children: [
                          CheckboxListTile.adaptive(
                            title: const Text("All"),
                            value: viewModel.selected.isEmpty,
                            enabled: viewModel.selected.isNotEmpty,
                            onChanged: (checked) {
                              if (checked == null) return;
                              if (checked) {
                                viewModel.clearSelection();
                              }
                            },
                          ),
                          const Divider(),
                        ],
                      );
                    }
                    final folder = viewModel.musicFolders[index - 1];
                    return CheckboxListTile.adaptive(
                      title: Text(folder.name),
                      value: viewModel.selected.contains(folder.id),
                      onChanged: (checked) {
                        if (checked == null) return;
                        if (checked) {
                          viewModel.select(folder.id);
                        } else {
                          viewModel.deselect(folder.id);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
