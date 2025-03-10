import 'package:crossonic/data/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/ui/common/dialogs/chooser.dart';
import 'package:crossonic/ui/common/dialogs/confirmation.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/utils/result.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddToPlaylistDialog {
  static Future<void> show(
      BuildContext context, String collectionName, List<Song> songs) async {
    final repository = context.read<PlaylistRepository>();
    final result = await repository.getPlaylists();
    if (!context.mounted) return;
    toastResult(context, result);
    switch (result) {
      case Err():
        return;
      case Ok():
    }
    final playlists = result.value;
    if (playlists.isEmpty) {
      Toast.show(context, "There are no playlists");
      return;
    }
    final index = await ChooserDialog.choose(context, "Add to playlist",
        playlists.map((a) => a.name).toList(), false);
    if (index == null || !context.mounted) return;
    final playlist = playlists[index];
    final r = await repository.getPlaylist(playlist.id);
    if (context.mounted) {
      toastResult(context, r);
    }
    switch (r) {
      case Err():
        return;
      case Ok():
    }
    if (r.value == null) {
      if (context.mounted) {
        Toast.show(context, "The chosen playlist does not exist");
      }
      return;
    }
    final playlistSongs = r.value!.tracks;
    final List<Song> songsToAdd = [];
    for (int i = 0; i < songs.length; i++) {
      Song s = songs[i];
      try {
        playlistSongs.firstWhere((element) => element.id == s.id);
        if (context.mounted) {
          final add = await ConfirmationDialog.showYesNo(context,
              title: "Add anyway?",
              message: "'${playlist.name}' already contains '${s.title}'.");
          if (add == null) return;
          if (!add) {
            continue;
          }
        }
        songsToAdd.add(s);
      } on StateError {
        songsToAdd.add(s);
      } catch (e) {
        print(e);
      }
    }
    if (songsToAdd.isEmpty) return;
    final r2 = await repository.addTracks(playlist.id, songsToAdd);
    if (context.mounted) {
      toastResult(
          context, r2, "Added '$collectionName' to '${playlists[index].name}'");
    }
  }
}
