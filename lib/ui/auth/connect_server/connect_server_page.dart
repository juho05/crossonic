import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/integrate_appimage.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/auth/connect_server/connect_server_viewmodel.dart';
import 'package:crossonic/ui/common/adaptive_dialog_action.dart';
import 'package:crossonic/ui/common/buttons.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntegrateAppImage(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Connect Server"),
          actions: [
            IconButton(
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: () {
                context.router.push(const DebugRoute());
              },
            )
          ],
        ),
        body: SafeArea(
          child: ListenableBuilder(
              listenable: viewModel,
              builder: (context, _) {
                return LayoutBuilder(builder: (context, constraints) {
                  final cardMode =
                      constraints.maxWidth > 800 && constraints.maxHeight > 570;
                  final currentServerUri =
                      _formKey.currentState?.value["serverUri"];
                  if (_formKey.currentState != null &&
                      (currentServerUri == null ||
                          (currentServerUri as String).isEmpty)) {
                    if (viewModel.serverUrl != null &&
                        viewModel.serverUrl!.isNotEmpty) {
                      _formKey.currentState!.patchValue({
                        "serverUri": viewModel.serverUrl,
                      });
                    }
                  }
                  return FormBuilder(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    initialValue: {
                      "serverUri": viewModel.serverUrl,
                    },
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(cardMode ? 8.0 : 0),
                        child: Padding(
                          padding: EdgeInsets.only(bottom: cardMode ? 58 : 0),
                          child: ClipRRect(
                            borderRadius: cardMode
                                ? BorderRadius.circular(15)
                                : BorderRadius.zero,
                            child: Material(
                              color: cardMode
                                  ? theme.brightness == Brightness.dark
                                      ? theme.colorScheme.surfaceContainerLow
                                      : theme.colorScheme.surfaceContainer
                                  : null,
                              child: Padding(
                                padding: cardMode
                                    ? EdgeInsets.symmetric(
                                        vertical: constraints.maxHeight < 625
                                            ? 12
                                            : 32,
                                        horizontal: 48)
                                    : const EdgeInsets.all(0),
                                child: SizedBox(
                                  width: 430,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Expanded(
                                        flex: cardMode ? 0 : 1,
                                        child: Padding(
                                          padding: EdgeInsets.all(
                                              cardMode ? 24 : 32),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: cardMode ? 220 : 256,
                                                height: constraints.maxHeight >
                                                        700
                                                    ? cardMode
                                                        ? 220
                                                        : 256
                                                    : min(
                                                        max(
                                                            constraints
                                                                    .maxHeight *
                                                                0.3,
                                                            80),
                                                        cardMode ? 220 : 256),
                                                child: AspectRatio(
                                                  aspectRatio: 1,
                                                  child: SvgPicture.asset(
                                                    "assets/icon/crossonic-foreground-monochrome.svg",
                                                    alignment:
                                                        Alignment.topCenter,
                                                    colorFilter:
                                                        ColorFilter.mode(
                                                            theme.colorScheme
                                                                .onSurface,
                                                            BlendMode.srcIn),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height:
                                                    constraints.maxHeight >= 510
                                                        ? 16
                                                        : 4,
                                              ),
                                              Text("Crossonic",
                                                  style: theme
                                                      .textTheme.headlineLarge),
                                              if (constraints.maxHeight >= 480)
                                                SizedBox(
                                                  height:
                                                      constraints.maxHeight >=
                                                              510
                                                          ? 16
                                                          : 4,
                                                ),
                                              if (constraints.maxHeight >= 480)
                                                const Text(
                                                  "Welcome! Crossonic is a cross-platform OpenSubsonic compatible music player.\n\nTo begin, just enter the URL of your server below:",
                                                  textAlign: TextAlign.center,
                                                )
                                            ],
                                          ),
                                        ),
                                      ),
                                      Material(
                                        color: cardMode
                                            ? theme.brightness ==
                                                    Brightness.dark
                                                ? theme.colorScheme
                                                    .surfaceContainerLow
                                                : theme.colorScheme
                                                    .surfaceContainer
                                            : null,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 32,
                                              top: 8,
                                              left: 12,
                                              right: 12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              FormBuilderTextField(
                                                name: "serverUri",
                                                //restorationId:
                                                //    "connect_server_page_serverUri",
                                                autocorrect: false,
                                                keyboardType: TextInputType.url,
                                                decoration: InputDecoration(
                                                  labelText: "Server URL",
                                                  prefixIcon:
                                                      const Icon(Icons.link),
                                                  suffixIcon: IconButton(
                                                    onPressed: () {
                                                      showAdaptiveDialog(
                                                        context: context,
                                                        barrierDismissible:
                                                            true,
                                                        builder: (context) =>
                                                            AlertDialog
                                                                .adaptive(
                                                          title: const Text(
                                                              "What is a server URL?"),
                                                          content: const Text(
                                                              "This URL tells Crossonic which server it should connect to. It must point to a Subsonic compatible server.\n\nExample: https://music.example.com"),
                                                          actions: [
                                                            AdaptiveDialogAction(
                                                              child: const Text(
                                                                  "Ok"),
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context),
                                                            )
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                    icon: const Icon(
                                                        Icons.info_outline),
                                                  ),
                                                  border:
                                                      const OutlineInputBorder(),
                                                ),
                                                validator: FormBuilderValidators
                                                    .compose([
                                                  FormBuilderValidators
                                                      .required(),
                                                  FormBuilderValidators.url(
                                                    protocols: [
                                                      "http",
                                                      "https"
                                                    ],
                                                    requireProtocol: true,
                                                    requireTld: true,
                                                  ),
                                                ]),
                                                onSubmitted: (_) => _submit(),
                                              ),
                                              const SizedBox(height: 24),
                                              ListenableBuilder(
                                                listenable: viewModel.connect,
                                                builder: (context, _) =>
                                                    SubmitButton(
                                                  onPressed:
                                                      !viewModel.connect.running
                                                          ? _submit
                                                          : null,
                                                  child: const Text("Connect"),
                                                ),
                                              ),
                                            ],
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
                });
              }),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState == null || viewModel.connect.running) {
      return;
    }
    if (!_formKey.currentState!.saveAndValidate()) {
      return;
    }
    await viewModel.connect
        .execute(Uri.parse(_formKey.currentState!.value["serverUri"]));
  }

  void _onResult() {
    if (viewModel.connect.completed) {
      context.router.replaceAll([const LoginRoute()]);
      viewModel.connect.clearResult();
      return;
    }

    if (viewModel.connect.error) {
      final result = viewModel.connect.result as Err;
      final String message;
      if (result.error is InvalidServerException) {
        message = "URL does not point to an OpenSubsonic compatible server";
      } else {
        message = "Failed to connect to server";
      }
      Toast.show(context, message);
      viewModel.connect.clearResult();
    }
  }
}
