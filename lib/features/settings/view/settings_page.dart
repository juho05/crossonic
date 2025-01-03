import 'package:crossonic/features/auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crossonic | Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text("Transcoding"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              context.push("/settings/transcoding");
            },
          ),
          ListTile(
            title: const Text("Replay Gain"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              context.push("/settings/replaygain");
            },
          ),
          ListTile(
            title: const Text("ListenBrainz"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              context.push("/settings/listenbrainz");
            },
          ),
          ListTile(
            title: const Text("Scan"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              context.push("/settings/scan");
            },
          ),
          ListTile(
            trailing: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          )
        ],
      ),
    );
  }
}
