import 'package:crossonic/repositories/subsonic/subsonic_repository.dart';
import 'package:flutter/material.dart';

class ArtistChooserDialog extends StatelessWidget {
  final Iterable<ArtistIDName> artists;
  const ArtistChooserDialog._(this.artists);

  static Future<String?> choose(
      BuildContext context, Iterable<ArtistIDName> artists) async {
    if (artists.isEmpty) return null;
    if (artists.length == 1) return artists.first.id;
    final artist = await showDialog<String>(
      context: context,
      builder: (context) {
        return ArtistChooserDialog._(artists);
      },
    );
    return artist;
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text("Choose an artist"),
      children: artists
          .map((a) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, a.id),
                child: Text(a.name),
              ))
          .toList(),
    );
  }
}
