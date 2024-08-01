import 'package:crossonic/components/state/layout.dart';
import 'package:crossonic/features/auth/state/auth_bloc.dart';
import 'package:crossonic/routing/router.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const AppView();
  }
}

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  static final _defaultLightColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue, brightness: Brightness.light);
  static final _defaultDarkColorScheme =
      ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark);
  bool noRestore = false;

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightColorScheme, darkColorScheme) {
        return BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            goRouter.refresh();
          },
          child: LayoutBuilder(builder: (context, constraints) {
            final layout = context.read<Layout>();
            final oldSize = layout.size;
            if (constraints.maxWidth > 1000) {
              layout.size = LayoutSize.desktop;
            } else {
              layout.size = LayoutSize.mobile;
            }
            if (oldSize != layout.size) {
              goRouter.refresh();
              Future.delayed(const Duration(milliseconds: 200))
                  .then((value) => setState(() {}));
              return MaterialApp(
                home: const Center(child: CircularProgressIndicator.adaptive()),
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  useMaterial3: true,
                  colorScheme: lightColorScheme ?? _defaultLightColorScheme,
                ),
                darkTheme: ThemeData(
                  useMaterial3: true,
                  colorScheme: darkColorScheme ?? _defaultDarkColorScheme,
                ),
              );
            }
            return MaterialApp.router(
              title: 'Crossonic',
              restorationScopeId: "crossonic_app",
              routerConfig: goRouter,
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: lightColorScheme ?? _defaultLightColorScheme,
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                colorScheme: darkColorScheme ?? _defaultDarkColorScheme,
              ),
            );
          }),
        );
      },
    );
  }
}
