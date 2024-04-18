import 'package:crossonic/page_transition.dart';
import 'package:flutter/material.dart';

class PlaylistsPage extends StatelessWidget {
  const PlaylistsPage({super.key});

  static Route<void> route() {
    return PageTransition(const PlaylistsPage());
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
