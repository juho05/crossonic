import 'package:crossonic/features/auth/auth.dart';
import 'package:crossonic/page_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  static Route route(BuildContext context, Object? arguments) {
    return PageTransition(const SettingsPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crossonic | Settings'),
        titleSpacing: 5,
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Logout'),
          onPressed: () {
            context.read<AuthBloc>().add(AuthLogoutRequested());
          },
        ),
      ),
    );
  }
}
