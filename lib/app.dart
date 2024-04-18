import 'package:crossonic/features/auth/state/auth_bloc.dart';
import 'package:crossonic/features/home/home.dart';
import 'package:crossonic/features/login/login.dart';
import 'package:crossonic/features/splash/splash.dart';
import 'package:crossonic/repositories/auth/auth_repository.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthRepository _authRepository;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository(http.Client());
  }

  @override
  void dispose() {
    _authRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: _authRepository,
      child: BlocProvider(
        create: (_) => AuthBloc(authRepository: _authRepository),
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  static final _defaultLightColorScheme =
      ColorScheme.fromSwatch(primarySwatch: Colors.blue);
  static final _defaultDarkColorScheme = ColorScheme.fromSwatch(
      primarySwatch: Colors.blue, brightness: Brightness.dark);

  final _navigatorKey = GlobalKey<NavigatorState>();
  NavigatorState get _navigator => _navigatorKey.currentState!;

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightColorScheme, darkColorScheme) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Crossonic',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightColorScheme ?? _defaultLightColorScheme,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkColorScheme ?? _defaultDarkColorScheme,
          ),
          builder: (context, child) {
            return BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                switch (state.status) {
                  case AuthStatus.authenticated:
                    _navigator.pushAndRemoveUntil<void>(
                      HomePage.route(),
                      (route) => false,
                    );
                  case AuthStatus.unauthenticated:
                    _navigator.pushAndRemoveUntil<void>(
                      LoginPage.route(),
                      (route) => false,
                    );
                  case AuthStatus.unknown:
                    break;
                }
              },
              child: child,
            );
          },
          onGenerateRoute: (_) => SplashPage.route(),
        );
      },
    );
  }
}
