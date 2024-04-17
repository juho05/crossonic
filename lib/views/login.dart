import 'package:crossonic/services/crossonic_server.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  String? serverHostError;
  String? passwordError;

  String serverHost = "";
  String username = "";
  String password = "";
  @override
  Widget build(BuildContext context) {
    var crossonicServer = context.watch<CrossonicServer>();
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
                      errorText: serverHostError,
                      border: const OutlineInputBorder(),
                      labelText: 'Server Host',
                      icon: const Icon(Icons.link),
                    ),
                    onSaved: (value) {
                      serverHost = value ?? "";
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid server host (e.g. example.com or music.example.com:1234)';
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
                    onSaved: (value) {
                      username = value ?? "";
                    },
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
                    onSaved: (value) {
                      password = value ?? "";
                    },
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
                    onPressed: () async {
                      setState(() {
                        serverHostError = null;
                        passwordError = null;
                      });
                      if (!_form.currentState!.validate()) {
                        return;
                      }
                      _form.currentState!.save();
                      if (!(await crossonicServer.connect(serverHost))) {
                        setState(() {
                          serverHostError = "Cannot reach server";
                        });
                        return;
                      }
                      var (signedIn, subsonicURL) =
                          await crossonicServer.login(username, password);
                      if (!signedIn) {
                        setState(() {
                          passwordError = "Wrong credentials";
                        });
                        return;
                      }
                      print(subsonicURL);
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
