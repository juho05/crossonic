import 'dart:io';

import 'package:crossonic/config/providers.dart';
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/routing/router.dart';
import 'package:crossonic/window_listener.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!(await FlutterSingleInstance().isFirstInstance())) {
    print("App is already running");
    final err = await FlutterSingleInstance().focus();
    if (err != null) {
      print("Error focusing running instance: $err");
    }
    exit(0);
  }

  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(
      size: Size(1300, 850),
      center: true,
      title: "Crossonic",
    );
    CrossonicWindowListener.enable();
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
    });
  }

  runApp(MultiProvider(
    providers: await providers,
    child: const MainApp(),
  ));
}

class MainApp extends StatelessWidget {
  static final _defaultLightColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue, brightness: Brightness.light);
  static final _defaultDarkColorScheme =
      ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark);
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = context.read<AuthRepository>();
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp.router(
          title: "Crossonic",
          restorationScopeId: "crossonic_app",
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightDynamic ?? _defaultLightColorScheme,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkDynamic ?? _defaultDarkColorScheme,
          ),
          debugShowCheckedModeBanner: false,
          routerConfig: AppRouter(authRepository: authRepository).config(
            reevaluateListenable: authRepository,
          ),
        );
      },
    );
  }
}
