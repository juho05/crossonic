import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:crossonic/ui/main/now_playing/now_playing_viewmodel.dart';
import 'package:flutter/material.dart';

List<ContextMenuOption> getNowPlayingMenuOptions(
        NowPlayingViewModel viewModel) =>
    [
      ContextMenuOption(
        title: "Add to priority queue",
        onSelected: () {
          // TODO
        },
        icon: Icons.playlist_play,
      ),
      ContextMenuOption(
        title: "Add to queue",
        onSelected: () {
          // TODO
        },
        icon: Icons.playlist_add,
      ),
      ContextMenuOption(
        title:
            viewModel.favorite ? "Remove from favorites" : "Add to favorites",
        onSelected: () {
          viewModel.toggleFavorite();
        },
        icon: viewModel.favorite ? Icons.heart_broken : Icons.favorite,
      ),
      ContextMenuOption(
        title: "Add to playlist",
        onSelected: () {
          // TODO
        },
        icon: Icons.playlist_add,
      ),
      ContextMenuOption(
        title: "Go to album",
        onSelected: () {
          // TODO
        },
        icon: Icons.album,
      ),
      ContextMenuOption(
        title: "Go to artist",
        onSelected: () {
          // TODO
        },
        icon: Icons.person,
      ),
    ];
