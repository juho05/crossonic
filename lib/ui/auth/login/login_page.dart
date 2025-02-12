import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/auth/login/login_viewmodel.dart';
import 'package:crossonic/utils/exceptions.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';

@RoutePage()
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with RestorationMixin {
  final _formKey = GlobalKey<FormBuilderState>();

  late LoginViewModel viewModel;
  late RestorableEnum<AuthType> _authType;

  @override
  void initState() {
    super.initState();
    viewModel = LoginViewModel(authRepository: context.read<AuthRepository>());
    viewModel.login.addListener(_onResult);
    _authType = RestorableEnum(viewModel.supportedAuthTypes[0],
        values: AuthType.values);
  }

  @override
  void dispose() {
    super.dispose();
    viewModel.login.removeListener(_onResult);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign in"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FormBuilder(
            key: _formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: Center(
              child: SizedBox(
                width: 430,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Expanded(
                      flex: 1,
                      child: Text("Sign in",
                          style: Theme.of(context).textTheme.displayMedium),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        spacing: 20,
                        children: [
                          Row(
                            children: [
                              Text("Server:",
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge!
                                      .copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text(viewModel.serverURL),
                              IconButton(
                                onPressed: () async {
                                  final router = context.router;
                                  await viewModel.resetServerUri();
                                  router.replaceAll([ConnectServerRoute()]);
                                },
                                icon: Icon(Icons.edit),
                              ),
                            ],
                          ),
                          DropdownButtonFormField<AuthType>(
                            value: _authType.value,
                            decoration: const InputDecoration(
                              labelText: "Authentication Method",
                              border: OutlineInputBorder(),
                              icon: Icon(Icons.alt_route),
                            ),
                            items: List.generate(
                              viewModel.supportedAuthTypes.length,
                              (index) {
                                return DropdownMenuItem(
                                  value: viewModel.supportedAuthTypes[index],
                                  child: Text(
                                    switch (
                                        viewModel.supportedAuthTypes[index]) {
                                      AuthType.apiKey => "API Key",
                                      AuthType.token => "Token",
                                      AuthType.password => "Password",
                                    },
                                  ),
                                );
                              },
                            ),
                            onChanged: (value) => setState(() {
                              _authType.value =
                                  value ?? viewModel.supportedAuthTypes[0];
                            }),
                          ),
                          if (_authType.value != AuthType.apiKey)
                            FormBuilderTextField(
                              name: "username",
                              restorationId: "login_page_username",
                              decoration: const InputDecoration(
                                labelText: "Username",
                                icon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              autofillHints: const [AutofillHints.username],
                              validator: FormBuilderValidators.required(),
                            ),
                          if (_authType.value != AuthType.apiKey)
                            FormBuilderTextField(
                              name: "password",
                              restorationId: "login_page_password",
                              decoration: const InputDecoration(
                                labelText: "Password",
                                icon: Icon(Icons.link),
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                              autofillHints: const [AutofillHints.password],
                              validator: FormBuilderValidators.required(),
                            ),
                          if (_authType.value == AuthType.apiKey)
                            FormBuilderTextField(
                              name: "apiKey",
                              restorationId: "login_page_apiKey",
                              decoration: const InputDecoration(
                                labelText: "API Key",
                                icon: Icon(Icons.key),
                                border: OutlineInputBorder(),
                              ),
                              autofillHints: const [AutofillHints.password],
                              validator: FormBuilderValidators.required(),
                            ),
                        ],
                      ),
                    ),
                    ListenableBuilder(
                      listenable: viewModel.login,
                      builder: (context, _) => ElevatedButton(
                        onPressed: !viewModel.login.running
                            ? () async {
                                if (_formKey.currentState == null ||
                                    viewModel.login.running) {
                                  return;
                                }
                                if (!_formKey.currentState!.saveAndValidate()) {
                                  return;
                                }
                                await viewModel.login.execute(LoginData(
                                  type: _authType.value,
                                  username: _authType.value != AuthType.apiKey
                                      ? _formKey.currentState!.value["username"]
                                      : null,
                                  password: _authType.value != AuthType.apiKey
                                      ? _formKey.currentState!.value["password"]
                                      : null,
                                  apiKey: _authType.value == AuthType.apiKey
                                      ? _formKey.currentState!.value["apiKey"]
                                      : null,
                                ));
                              }
                            : null,
                        style: ButtonStyle(),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text("Sign in"),
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onResult() {
    if (viewModel.login.completed) {
      context.router.replaceAll([MainRoute()]);
      viewModel.login.clearResult();
      return;
    }

    if (viewModel.login.error) {
      final result = viewModel.login.result as Error;
      final String message;
      if (result.error is UnauthenticatedException) {
        message = "Incorrect credentials";
      } else if (result.error is ConnectionException) {
        message = "Failed to contact server";
      } else {
        message = "An unexpected error occured";
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      viewModel.login.clearResult();
    }
  }

  @override
  String? get restorationId => "login_page";

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_authType, "auth_type");
  }
}
