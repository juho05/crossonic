import 'dart:io';

import 'package:crossonic/config/providers.dart';
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/routing/router.dart';
import 'package:crossonic/window_listener.dart';
import 'package:dynamic_system_colors/dynamic_system_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  Log.init();
  Log.info("App started.");

  WidgetsFlutterBinding.ensureInitialized();

  FlutterSingleInstance.onFocus = (metadata) async {
    if (!(await windowManager.isVisible())) {
      await windowManager.show();
    }
  };

  if (!(await FlutterSingleInstance().isFirstInstance())) {
    Log.info("App is already running. Trying to focus running instance...");
    final err = await FlutterSingleInstance().focus();
    if (err != null) {
      Log.error("Failed to focus running instance", err);
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
