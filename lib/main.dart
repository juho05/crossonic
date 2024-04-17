import 'package:crossonic/services/crossonic_server.dart';
import 'package:crossonic/views/login.dart';
import 'package:crossonic/views/main.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(ChangeNotifierProvider(
    create: (context) => CrossonicServer(),
    child: const App(),
  ));
}

class App extends StatelessWidget {
  const App({super.key});

  static final _defaultLightColorScheme =
      ColorScheme.fromSwatch(primarySwatch: Colors.red);
  static final _defaultDarkColorScheme = ColorScheme.fromSwatch(
      primarySwatch: Colors.red, brightness: Brightness.dark);

  @override
  Widget build(BuildContext context) {
    var crossonicServer = context.watch<CrossonicServer>();
    Widget home;
    if (crossonicServer.authToken == null) {
      home = const LoginPage();
    } else {
      home = const MainPage();
    }
    return DynamicColorBuilder(
      builder: (lightColorScheme, darkColorScheme) {
        return MaterialApp(
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
          home: home,
        );
      },
    );
  }
}
