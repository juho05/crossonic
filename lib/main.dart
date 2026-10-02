/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:audio_service_mpris/mpris.dart';
import 'package:crossonic/app_shortcuts.dart';
import 'package:crossonic/config/providers.dart';
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/logger/log_repository.dart';
import 'package:crossonic/data/repositories/themeManager/theme_manager.dart';
import 'package:crossonic/data/services/methodchannel/method_channel_service.dart';
import 'package:crossonic/routing/router.dart';
import 'package:crossonic/ui/common/volume_hud.dart';
import 'package:crossonic/window_listener.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';
import 'package:flutter_system_integration/flutter_system_integration.dart';
import 'package:material_ui/material_ui.dart';
import 'package:predictive_transition/predictive_transition.dart';
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
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSizeBytes = 200 << 20; // 200 MB

  MethodChannelService methodChannelService = MethodChannelService();

  LogRepository logRepository = LogRepository();

  Log.init(logRepository, methodChannelService);

  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString(
      "assets/fonts/Roboto_LICENSE.txt",
    );
    yield LicenseEntryWithLineBreaks(["Roboto"], license);
  });
  // only these platforms bundle media_kit's prebuilt libmpv, the Linux AppImage ships its own license files
  if (!kIsWeb && (Platform.isIOS || Platform.isMacOS || Platform.isWindows)) {
    LicenseRegistry.addLicense(_mediaLibraryLicenses);
  }

  Log.info(
    "App started. Engine ID: ${PlatformDispatcher.instance.engineId}, Configuration: ${kDebugMode
        ? "debug"
        : kProfileMode
        ? "profile"
        : "release"}",
  );

  if (kIsWasm) {
    Log.info("Running on WebAssembly");
  } else if (kIsWeb) {
    Log.info("Running on JavaScript");
  }

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

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
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

  if (!kIsWeb && kReleaseMode && Platform.isAndroid) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
      Log.debug("Enabled high refresh rate");
    } catch (e, st) {
      Log.warn("Failed to enable high refresh rate", e: e, st: st);
    }
  }

  runApp(
    MultiProvider(
      providers: await createProviders(
        methodChannelService: methodChannelService,
        logRepository: logRepository,
      ),
      child: AppShortcuts(
        child: Builder(
          builder: (context) {
            final routerConfig = AppRouter(authRepository: context.read())
                .config(reevaluateListenable: context.read<AuthRepository>());
            return MainApp(routerConfig: routerConfig);
          },
        ),
      ),
    ),
  );
}

Stream<LicenseEntry> _mediaLibraryLicenses() async* {
  final lgpl3 = await rootBundle.loadString("assets/licenses/LGPL-3.0.txt");
  final gpl3 = await rootBundle.loadString("assets/licenses/GPL-3.0.txt");
  final lgpl21 = await rootBundle.loadString("assets/licenses/LGPL-2.1.txt");
  final apache2 = await rootBundle.loadString("assets/licenses/Apache-2.0.txt");
  final mpvSource = Platform.isWindows
      ? "https://github.com/mpv-player/mpv/tree/652a1dd907"
      : "https://github.com/mpv-player/mpv/tree/v0.36.0";

  yield const LicenseEntryWithLineBreaks(
    ["FFmpeg"],
    "This software uses libraries from the FFmpeg project licensed under the "
    "LGPLv3. The source code can be downloaded from "
    "https://ffmpeg.org/releases/ffmpeg-6.0.tar.xz",
  );
  yield LicenseEntryWithLineBreaks(["FFmpeg"], lgpl3);
  yield LicenseEntryWithLineBreaks(["FFmpeg"], gpl3);
  yield LicenseEntryWithLineBreaks(
    ["mpv"],
    "This software uses libmpv licensed under the LGPLv2.1 or later. The "
    "source code can be downloaded from $mpvSource",
  );
  yield LicenseEntryWithLineBreaks(["mpv"], lgpl21);
  yield LicenseEntryWithLineBreaks(["Mbed TLS"], apache2);
}

class MainApp extends StatelessWidget {
  final RouterConfig<Object> _routerConfig;

  const MainApp({super.key, required this._routerConfig});

  static const _pageTransitions = PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: PredictiveTransitionPageTransitionsBuilder(),
    },
  );

  static const _fontFamily = "Roboto";

  @override
  Widget build(BuildContext context) {
    final themeManager = context.read<ThemeManager>();
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return ListenableBuilder(
          listenable: themeManager,
          builder: (context, _) {
            var lightPrimary = lightDynamic?.primary;
            var darkPrimary = darkDynamic?.primary;
            if (!themeManager.enableDynamicColors) {
              lightPrimary = null;
              darkPrimary = null;
            }
            lightPrimary ??= Colors.blue;
            darkPrimary ??= Colors.blue;
            return MaterialApp.router(
              title: "Crossonic",
              restorationScopeId: "crossonic_app",
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: lightPrimary,
                  brightness: Brightness.light,
                ),
                pageTransitionsTheme: _pageTransitions,
                fontFamily: _fontFamily,
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: darkPrimary,
                  brightness: Brightness.dark,
                ),
                pageTransitionsTheme: _pageTransitions,
                fontFamily: _fontFamily,
              ),
              themeMode: themeManager.themeMode,
              debugShowCheckedModeBanner: false,
              routerConfig: _routerConfig,
              builder: (context, child) => Stack(
                children: [
                  // needed for audio_video_progress_bar and month_picker_dialog
                  // ignore: deprecated_member_use
                  MaterialUiCompatibilityBridge(child: child!),
                  const Positioned.fill(child: VolumeHud()),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
