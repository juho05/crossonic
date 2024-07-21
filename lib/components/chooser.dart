// ignore_for_file: use_build_context_synchronously

import 'package:crossonic/exceptions.dart';
import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:crossonic/repositories/api/models/media_model.dart';
import 'package:crossonic/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/components/confirmation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChooserDialog extends StatelessWidget {
  final String title;
  final List<String> options;
  const ChooserDialog._({
    required this.title,
    required this.options,
  });

  static Future<int?> choose(
      BuildContext context, String title, List<String> options,
      [bool autoChooseOnOneOption = true]) async {
    if (options.isEmpty) return null;
    if (autoChooseOnOneOption && options.length == 1) return 0;
    final index = await showAdaptiveDialog<int>(
      context: context,
      builder: (context) {
        return ChooserDialog._(
          title: title,
          options: options,
        );
      },
    );
    return index;
  }

  static Future<String?> chooseArtist(
      BuildContext context, List<ArtistIDName> artists) async {
    final index = await choose(
        context, "Choose an artist", artists.map((a) => a.name).toList());
    if (index == null) return null;
    return artists[index].id;
  }

  static Future<void> addToPlaylist(
      BuildContext context, String collectionName, List<Media> songs) async {
    final repository = context.read<PlaylistRepository>();
    final playlists = repository.playlists.value;
    if (playlists.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text("There are no playlists")));
      return;
    }
    final index = await choose(context, "Add to playlist",
        playlists.map((a) => a.name).toList(), false);
    if (index == null) return;
    final playlist = playlists[index];
    final playlistSongs =
        (await repository.getUpdatedPlaylist(playlist.id)).entry ?? [];
    final List<Media> songsToAdd = [];
    for (int i = 0; i < songs.length; i++) {
      Media s = songs[i];
      try {
        playlistSongs.firstWhere((element) => element.id == s.id);
        final add = await ConfirmationDialog.showYesNo(context, "Add anyway?",
            "'${playlist.name}' already contains '${s.title}'.");
        if (add == null) return;
        if (add) {
          songsToAdd.add(s);
        }
      } on StateError {
        songsToAdd.add(s);
      } catch (e) {
        print(e);
      }
    }
    if (songsToAdd.isEmpty) return;
    try {
      await repository.addSongsToPlaylist(playlist.id, songsToAdd);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content:
                Text("Added '$collectionName' to '${playlists[index].name}'")));
    } on ServerUnreachableException {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
              const SnackBar(content: Text("Cannot connect to server")));
      }
    } catch (e) {
      print(e);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
              const SnackBar(content: Text("An unexpected error occured")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(title),
      children: List.generate(
        options.length,
        (index) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, index),
          child: Text(options[index]),
        ),
      ),
    );
  }
}
