import 'package:flutter/material.dart';

class PlaylistsPage extends StatelessWidget {
  const PlaylistsPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const PlaylistsPage());
  }

  @override
  Widget build(BuildContext context) {
    return const Material(
      child: Center(
        child: Text('Playlists'),
      ),
    );
  }
}
