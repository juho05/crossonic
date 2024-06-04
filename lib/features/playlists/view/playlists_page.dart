import 'package:crossonic/widgets/app_bar.dart';
import 'package:flutter/material.dart';

class PlaylistsPage extends StatelessWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createAppBar(context, "Playlists"),
      body: const Center(
        child: Text('Playlists'),
      ),
    );
  }
}
