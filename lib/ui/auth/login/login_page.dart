import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class LoginPage extends StatelessWidget {
  const LoginPage({super.key, this.onSignedIn});

  final void Function()? onSignedIn;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign in"),
        leading: AutoLeadingButton(),
      ),
      body: Text("Login Page"),
    );
  }
}
