import 'package:crossonic/features/login/login.dart';
import 'package:crossonic/page_transition.dart';
import 'package:crossonic/repositories/auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  static Route route() {
    return PageTransition(const LoginPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.music_note),
        title: const Text('Crossonic'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: BlocProvider(
          create: (context) {
            return LoginBloc(authRepository: context.read<AuthRepository>());
          },
          child: const LoginForm(),
        ),
      ),
    );
  }
}
