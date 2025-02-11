import 'package:crossonic/config/providers.dart';
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/routing/router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  runApp(MultiProvider(
    providers: providers,
    child: const MainApp(),
  ));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = context.read<AuthRepository>();
    return MaterialApp.router(
      title: "Crossonic",
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter(authRepository: authRepository).config(
        reevaluateListenable: authRepository,
      ),
    );
  }
}
