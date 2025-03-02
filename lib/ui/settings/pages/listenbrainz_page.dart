import 'package:auto_route/auto_route.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/ui/settings/pages/listenbrainz_viewmodel.dart';
import 'package:crossonic/utils/exceptions.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';

@RoutePage()
class ListenBrainzPage extends StatefulWidget {
  const ListenBrainzPage({super.key});

  @override
  State<ListenBrainzPage> createState() => _ListenBrainzPageState();
}

class _ListenBrainzPageState extends State<ListenBrainzPage> {
  late final ListenBrainzViewModel _viewModel;

  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    _viewModel = ListenBrainzViewModel(
      subsonicRepository: context.read(),
    )..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ListenBrainz"),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.status == FetchStatus.failure) {
            return const Center(child: Icon(Icons.wifi_off));
          }
          if (_viewModel.status != FetchStatus.success) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FormBuilder(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  if (_viewModel.username != null)
                    Text("Connected: ${_viewModel.username}")
                  else
                    FormBuilderTextField(
                      name: "apiToken",
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: "API Token",
                        border: const OutlineInputBorder(),
                        icon: const Icon(Icons.key),
                      ),
                      validator: FormBuilderValidators.required(),
                      onSubmitted: (value) => _submit(context),
                    ),
                  const SizedBox(height: 15),
                  if (_viewModel.username == null)
                    Padding(
                      padding: const EdgeInsets.only(left: 38),
                      child: ElevatedButton(
                        onPressed: !_viewModel.submitting
                            ? () => _submit(context)
                            : null,
                        child: _viewModel.submitting
                            ? const Text("Connecting…")
                            : const Text("Connect"),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: !_viewModel.submitting
                          ? () async {
                              final result = await _viewModel.disconnect();
                              if (!context.mounted) return;
                              toastResult(context, result);
                            }
                          : null,
                      child: _viewModel.submitting
                          ? const Text("Disconnecting…")
                          : const Text("Disconnect"),
                    )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (_formKey.currentState == null || _viewModel.submitting) {
      return;
    }
    if (!_formKey.currentState!.saveAndValidate()) {
      return;
    }
    final result =
        await _viewModel.connect(_formKey.currentState!.value["apiToken"]);
    if (!context.mounted) return;
    if (result is Err && result.error is! ConnectionException) {
      Toast.show(context, "Invalid token");
      return;
    }
    toastResult(context, result);
  }
}
