import 'package:crossonic/features/login/login.dart';
import 'package:crossonic/repositories/api/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crossonic | Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: BlocProvider(
          create: (context) {
            return LoginBloc(apiRepository: context.read<APIRepository>());
          },
          child: const LoginForm(),
        ),
      ),
    );
  }
}
