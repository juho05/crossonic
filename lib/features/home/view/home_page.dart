import 'package:crossonic/features/home/state/nav_bloc.dart';
import 'package:crossonic/features/playlists/playlists.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const HomePage());
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: Column(
          children: [
            const Text('Home'),
            ElevatedButton(
              onPressed: () =>
                  context.read<NavBloc>().add(NavPushed(PlaylistsPage.route())),
              child: const Text("push"),
            )
          ],
        ),
      ),
    );
  }
}
