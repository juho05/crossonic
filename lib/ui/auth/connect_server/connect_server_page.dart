import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/auth/connect_server/connect_server_viewmodel.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';

@RoutePage()
class ConnectServerPage extends StatefulWidget {
  const ConnectServerPage({
    super.key,
  });

  @override
  State<ConnectServerPage> createState() => _ConnectServerPageState();
}

class _ConnectServerPageState extends State<ConnectServerPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  late ConnectServerViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel =
        ConnectServerViewModel(authRepository: context.read<AuthRepository>());
    viewModel.connect.addListener(_onResult);
  }

  @override
  void dispose() {
    super.dispose();
    viewModel.connect.removeListener(_onResult);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Connect Server"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FormBuilder(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Center(
              child: SizedBox(
                width: 430,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Expanded(
                      child: Text("Welcome!",
                          style: Theme.of(context).textTheme.displayMedium),
                    ),
                    Expanded(
                      child: FormBuilderTextField(
                        name: "serverUri",
                        restorationId: "connect_server_page_serverUri",
                        decoration: const InputDecoration(
                          labelText: "Server URL",
                          icon: Icon(Icons.link),
                          border: OutlineInputBorder(),
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.url(
                            protocols: ["http", "https"],
                            requireProtocol: true,
                            requireTld: true,
                          ),
                        ]),
                      ),
                    ),
                    ListenableBuilder(
                      listenable: viewModel.connect,
                      builder: (context, _) => ElevatedButton(
                        onPressed: !viewModel.connect.running
                            ? () async {
                                if (_formKey.currentState == null ||
                                    viewModel.connect.running) {
                                  return;
                                }
                                if (!_formKey.currentState!.saveAndValidate()) {
                                  return;
                                }
                                await viewModel.connect.execute(Uri.parse(
                                    _formKey.currentState!.value["serverUri"]));
                              }
                            : null,
                        style: ButtonStyle(),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text("Connect"),
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
    if (viewModel.connect.completed) {
      context.router.replaceAll([LoginRoute()]);
      viewModel.connect.clearResult();
      return;
    }

    if (viewModel.connect.error) {
      final result = viewModel.connect.result as Error;
      final String message;
      if (result.error is InvalidServerException) {
        message = "URL does not point to an OpenSubsonic compatible server";
      } else {
        message = "Failed to connect to server";
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      viewModel.connect.clearResult();
    }
  }
}
