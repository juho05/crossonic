import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/auth/login/login_viewmodel.dart';
import 'package:crossonic/ui/common/buttons.dart';
import 'package:crossonic/ui/common/toast.dart';
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
    viewModel.login.removeListener(_onResult);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign in"),
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final cardMode =
              constraints.maxWidth > 800 && constraints.maxHeight > 570;
          final theme = Theme.of(context);
          final child = Center(
            child: Padding(
              padding: EdgeInsets.all(cardMode ? 8.0 : 0),
              child: ClipRRect(
                borderRadius:
                    cardMode ? BorderRadius.circular(15) : BorderRadius.zero,
                child: Material(
                  color: cardMode
                      ? theme.brightness == Brightness.dark
                          ? theme.colorScheme.surfaceContainerLow
                          : theme.colorScheme.surfaceContainer
                      : null,
                  child: Padding(
                    padding: cardMode
                        ? EdgeInsets.symmetric(
                            vertical: constraints.maxHeight < 625 ? 12 : 32,
                            horizontal: 48)
                        : const EdgeInsets.all(16),
                    child: SizedBox(
                      width: 430,
                      child: FormBuilder(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.disabled,
                        child: AutofillGroup(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: 16,
                            children: [
                              Row(
                                children: [
                                  Text("Server:",
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge!
                                          .copyWith(
                                              fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Text(viewModel.serverURL),
                                  IconButton(
                                    onPressed: () async {
                                      await viewModel.resetServerUri();
                                    },
                                    icon: Icon(Icons.edit),
                                  ),
                                ],
                              ),
                              DropdownMenu<AuthType>(
                                initialSelection: _authType.value,
                                expandedInsets: EdgeInsets.zero,
                                requestFocusOnTap: false,
                                enableSearch: false,
                                leadingIcon: Icon(Icons.login),
                                dropdownMenuEntries: List.generate(
                                  viewModel.supportedAuthTypes.length,
                                  (index) {
                                    return DropdownMenuEntry(
                                      value:
                                          viewModel.supportedAuthTypes[index],
                                      label: switch (viewModel
                                              .supportedAuthTypes[index]) {
                                            AuthType.apiKey => "API Key",
                                            AuthType.token => "Token",
                                            AuthType.password => "Password",
                                          } +
                                          (index == 0 ? " (recommended)" : ""),
                                    );
                                  },
                                ),
                                onSelected: (value) => setState(() {
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
                                    prefixIcon: Icon(Icons.person),
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
                                    prefixIcon: Icon(Icons.link),
                                    border: OutlineInputBorder(),
                                  ),
                                  obscureText: true,
                                  autofillHints: const [AutofillHints.password],
                                  validator: FormBuilderValidators.required(),
                                  onSubmitted: (_) => _submit(),
                                ),
                              if (_authType.value == AuthType.apiKey)
                                FormBuilderTextField(
                                  name: "apiKey",
                                  restorationId: "login_page_apiKey",
                                  decoration: const InputDecoration(
                                    labelText: "API Key",
                                    prefixIcon: Icon(Icons.key),
                                    border: OutlineInputBorder(),
                                  ),
                                  autofillHints: const [AutofillHints.password],
                                  validator: FormBuilderValidators.required(),
                                  onSubmitted: (_) => _submit(),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: ListenableBuilder(
                                  listenable: viewModel.login,
                                  builder: (context, _) => SubmitButton(
                                    onPressed: !viewModel.login.running
                                        ? _submit
                                        : null,
                                    child: Text("Sign in"),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          if (cardMode) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 58),
              child: child,
            );
          }
          return SingleChildScrollView(
            child: child,
          );
        }),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState == null || viewModel.login.running) {
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

  void _onResult() {
    if (viewModel.login.completed) {
      context.router.replaceAll([MainRoute()]);
      viewModel.login.clearResult();
      return;
    }

    if (viewModel.login.error) {
      final result = viewModel.login.result as Err;
      final String message;
      if (result.error is UnauthenticatedException) {
        message = "Incorrect credentials";
      } else if (result.error is ConnectionException) {
        message = "Failed to contact server";
      } else {
        message = "An unexpected error occured";
      }
      Toast.show(context, message);
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
