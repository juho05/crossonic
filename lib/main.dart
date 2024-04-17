import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(ChangeNotifierProvider(
    create: (context) => SubsonicModel(),
    child: const App(),
  ));
}

class SubsonicModel extends ChangeNotifier {
  String? _authToken;
  String? get authToken => _authToken;
  set authToken(String? token) {
    _authToken = authToken;
    notifyListeners();
  }
}

class App extends StatelessWidget {
  const App({super.key});

  static final _defaultLightColorScheme =
      ColorScheme.fromSwatch(primarySwatch: Colors.red);
  static final _defaultDarkColorScheme = ColorScheme.fromSwatch(
      primarySwatch: Colors.red, brightness: Brightness.dark);

  @override
  Widget build(BuildContext context) {
    var subsonicModel = context.watch<SubsonicModel>();
    Widget home;
    print(subsonicModel.authToken);
    if (subsonicModel.authToken == null) {
      home = const PageLogin();
    } else {
      home = const PageMain();
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

class PageLogin extends StatefulWidget {
  const PageLogin({super.key});

  @override
  State<PageLogin> createState() => _PageLoginState();
}

class _PageLoginState extends State<PageLogin> {
  final _form = GlobalKey<FormState>();
  String? serverURLError;
  String? passwordError;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crossonic'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Center(
          child: SizedBox(
            width: 430,
            child: Form(
              key: _form,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Login',
                      style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 80),
                  TextFormField(
                    autofillHints: const [AutofillHints.url],
                    decoration: InputDecoration(
                      errorText: serverURLError,
                      border: const OutlineInputBorder(),
                      labelText: 'Server URL',
                      icon: const Icon(Icons.link),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid server URL';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      icon: Icon(Icons.person),
                      labelText: 'Username',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    autofillHints: const [AutofillHints.password],
                    obscureText: true,
                    decoration: InputDecoration(
                      errorText: passwordError,
                      icon: const Icon(Icons.password),
                      border: const OutlineInputBorder(),
                      labelText: 'Password',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 80),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 20)),
                    onPressed: () {
                      setState(() {
                        if (!_form.currentState!.validate()) {
                          print("invalid");
                          return;
                        }
                      });
                    },
                    child: const Text('Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PageMain extends StatelessWidget {
  const PageMain({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crossonic'),
      ),
    );
  }
}
