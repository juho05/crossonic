import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/dialogs/add_to_playlist.dart';
import 'package:crossonic/ui/common/dialogs/chooser.dart';
import 'package:crossonic/ui/common/dialogs/media_info.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:crossonic/ui/main/now_playing/now_playing_viewmodel.dart';
import 'package:flutter/material.dart';

List<ContextMenuOption> getNowPlayingMenuOptions(
        BuildContext context, NowPlayingViewModel viewModel) =>
    [
      ContextMenuOption(
        title: "Add to priority queue",
        onSelected: () {
          viewModel.addToQueue(true);
          Toast.show(
              context, "Added '${viewModel.songTitle}' to priority queue");
        },
        icon: Icons.playlist_play,
      ),
      ContextMenuOption(
        title: "Add to queue",
        onSelected: () {
          viewModel.addToQueue(false);
          Toast.show(context, "Added '${viewModel.songTitle}' to queue");
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
          if (viewModel.song == null) return;
          AddToPlaylistDialog.show(
              context, viewModel.songTitle, [viewModel.song!]);
        },
        icon: Icons.playlist_add,
      ),
      if (viewModel.album != null)
        ContextMenuOption(
          title: "Go to release",
          onSelected: () {
            context.router.push(AlbumRoute(albumId: viewModel.album!.id));
          },
          icon: Icons.album,
        ),
      if (viewModel.artists.isNotEmpty)
        ContextMenuOption(
          title: "Go to artist",
          onSelected: () async {
            final artistId = await ChooserDialog.chooseArtist(
                context, viewModel.artists.toList());
            if (!context.mounted || artistId == null) return;
            context.router.push(ArtistRoute(artistId: artistId));
          },
          icon: Icons.person,
        ),
      ContextMenuOption(
        title: "Info",
        icon: Icons.info_outline,
        onSelected: () {
          MediaInfoDialog.showSong(context, viewModel.song!.id);
        },
      ),
    ];
