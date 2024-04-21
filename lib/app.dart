import 'package:crossonic/features/auth/state/auth_bloc.dart';
import 'package:crossonic/features/home/view/state/home_cubit.dart';
import 'package:crossonic/repositories/auth/auth_repository.dart';
import 'package:crossonic/repositories/subsonic/subsonic.dart';
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
  late final AuthRepository _authRepository;
  late final SubsonicRepository _subsonicRepository;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository();
    _subsonicRepository = SubsonicRepository(_authRepository);
  }

  @override
  void dispose() {
    _authRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _authRepository),
        RepositoryProvider.value(value: _subsonicRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
              create: (_) => AuthBloc(authRepository: _authRepository)),
          BlocProvider(
            create: (_) => HomeCubit(_subsonicRepository)..fetchRandomSongs(),
          ),
        ],
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

  bool noRestore = false;

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightColorScheme, darkColorScheme) {
        return BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            goRouter.refresh();
          },
          child: MaterialApp.router(
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
          ),
        );
      },
    );
  }
}
