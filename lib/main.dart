import 'dart:io';

import 'package:crossonic/app_shortcuts.dart';
import 'package:crossonic/config/providers.dart';
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/themeManager/theme_manager.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/version/version.dart';
import 'package:crossonic/data/repositories/version/version_repository.dart';
import 'package:crossonic/routing/router.dart';
import 'package:crossonic/window_listener.dart';
import 'package:dynamic_system_colors/dynamic_system_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';
import 'package:window_manager/window_manager.dart';
import 'package:xdg_directories/xdg_directories.dart' as xdg;

final defaultLightColorScheme =
    ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light);
final defaultDarkColorScheme =
    ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark);

void main() async {
  if (!kIsWeb && Platform.isLinux) {
    await _migrateAppSupportDir();
  }

  Log.init();
  Log.info("App started.");

  if (kIsWasm) {
    Log.info("Running on WebAssembly");
  } else if (kIsWeb) {
    Log.info("Running on JavaScript");
  }

  WidgetsFlutterBinding.ensureInitialized();

  FlutterSingleInstance.onFocus = (metadata) async {
    try {
      Version version = Version.fromJson(metadata);
      final currentVersion = await VersionRepository.getCurrentVersion();
      if (currentVersion != version) {
        Log.info(
            "An instance with different version is trying to start, exiting...");
        exit(0);
      }
    } catch (_) {}

    if (!(await windowManager.isVisible())) {
      await windowManager.show();
    }
  };

  if (!(await FlutterSingleInstance().isFirstInstance())) {
    Log.info("App is already running. Trying to focus running instance...");
    final err = await FlutterSingleInstance()
        .focus(await VersionRepository.getCurrentVersion());
    if (err == null) {
      exit(0);
    } else {
      Log.warn("Failed to focus running instance");
    }
  }

  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1300, 850),
      center: true,
      title: "Crossonic",
    );
    CrossonicWindowListener.enable();
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
    });
  }

  runApp(
    MultiProvider(
      providers: await providers,
      child: AppShortcuts(child: Builder(builder: (context) {
        final routerConfig = AppRouter(authRepository: context.read()).config(
          reevaluateListenable: context.read<AuthRepository>(),
        );
        return MainApp(
          routerConfig: routerConfig,
        );
      })),
    ),
  );
}

class MainApp extends StatelessWidget {
  final RouterConfig<Object> _routerConfig;

  const MainApp({super.key, required RouterConfig<Object> routerConfig})
      : _routerConfig = routerConfig;

  @override
  Widget build(BuildContext context) {
    final themeManager = context.read<ThemeManager>();
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return ListenableBuilder(
            listenable: themeManager,
            builder: (context, _) {
              var lightTheme = lightDynamic;
              var darkTheme = darkDynamic;
              if (!themeManager.enableDynamicColors) {
                lightTheme = null;
                darkTheme = null;
              }
              return MaterialApp.router(
                title: "Crossonic",
                restorationScopeId: "crossonic_app",
                theme: ThemeData(
                  useMaterial3: true,
                  colorScheme: lightTheme ?? defaultLightColorScheme,
                ),
                darkTheme: ThemeData(
                  useMaterial3: true,
                  colorScheme: darkTheme ?? defaultDarkColorScheme,
                ),
                themeMode: themeManager.themeMode,
                debugShowCheckedModeBanner: false,
                routerConfig: _routerConfig,
              );
            });
      },
    );
  }
}

Future<void> _migrateAppSupportDir() async {
  final oldDir = Directory(join(xdg.dataHome.path, "Crossonic"));
  final newDir = Directory(join(xdg.dataHome.path, "org.crossonic.app"));
  if (!await oldDir.exists() || await newDir.exists()) {
    return;
  }

  try {
    await oldDir.rename(newDir.path);
  } catch (e) {
    print(
        "Failed to move old application support directory to new location: $e");
  }
}
