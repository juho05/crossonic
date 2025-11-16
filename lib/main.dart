import 'dart:io';

import 'package:audio_service_mpris/mpris.dart';
import 'package:crossonic/app_shortcuts.dart';
import 'package:crossonic/config/providers.dart';
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/logger/log_repository.dart';
import 'package:crossonic/data/repositories/themeManager/theme_manager.dart';
import 'package:crossonic/data/repositories/version/version.dart';
import 'package:crossonic/data/repositories/version/version_repository.dart';
import 'package:crossonic/routing/router.dart';
import 'package:crossonic/window_listener.dart';
import 'package:dynamic_system_colors/dynamic_system_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

final defaultLightColorScheme = ColorScheme.fromSeed(
  seedColor: Colors.blue,
  brightness: Brightness.light,
);
final defaultDarkColorScheme = ColorScheme.fromSeed(
  seedColor: Colors.blue,
  brightness: Brightness.dark,
);

void main() async {
  LogRepository logRepository = LogRepository();

  if (!kIsWeb && Platform.isWindows) {
    await _migrateAppSupportDir();
  }

  Log.init(logRepository);
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
          "An instance with a different version is trying to start, exiting...",
        );
        exit(0);
      }
    } catch (_) {}

    if (!(await windowManager.isVisible())) {
      await windowManager.show();
    }
  };

  if (!(await FlutterSingleInstance().isFirstInstance())) {
    Log.info("App is already running. Trying to focus running instance...");
    final err = await FlutterSingleInstance().focus(
      await VersionRepository.getCurrentVersion(),
    );
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
    if (Platform.isLinux) {
      OrgMprisMediaPlayer2.onRaise = () => windowManager.show();
    }
  }

  if (kReleaseMode && Platform.isAndroid) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
      Log.debug("Enabled high refresh rate");
    } catch (e, st) {
      Log.warn("Failed to enable high refresh rate", e: e, st: st);
    }
  }

  runApp(
    MultiProvider(
      providers: await createProviders(logRepository: logRepository),
      child: AppShortcuts(
        child: Builder(
          builder: (context) {
            final routerConfig = AppRouter(
              authRepository: context.read(),
            ).config(reevaluateListenable: context.read<AuthRepository>());
            return MainApp(routerConfig: routerConfig);
          },
        ),
      ),
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
          },
        );
      },
    );
  }
}

Future<void> _migrateAppSupportDir() async {
  final localappdata = Platform.environment["LOCALAPPDATA"];
  if (localappdata == null) {
    Log.warn(
      "failed to delete old cache dir: LOCALAPPDATA environment variable does not exist",
    );
  } else {
    final dir = Directory(path.join(localappdata, "Julian Hofmann"));
    if (await dir.exists()) {
      try {
        dir.delete(recursive: true);
      } catch (e, st) {
        Log.warn("failed to delete old cache dir", e: e, st: st);
      }
    }
  }

  final appdata = Platform.environment["APPDATA"];
  if (appdata == null) {
    Log.warn(
      "failed to migrate app data: LOCALAPPDATA environment variable does not exist",
    );
    return;
  }

  final oldDir = Directory(path.join(appdata, "Julian Hofmann"));
  final newDir = Directory(path.join(appdata, "juho05"));

  if (!await oldDir.exists()) {
    return;
  }
  if (await newDir.exists()) {
    try {
      oldDir.delete(recursive: true);
    } catch (e, st) {
      Log.error("failed to delete old app data directory", e: e, st: st);
    }
    return;
  }

  try {
    await oldDir.rename(newDir.path);
  } catch (e, st) {
    Log.error(
      "Failed to move old app data directory to new location",
      e: e,
      st: st,
    );
  }
}
