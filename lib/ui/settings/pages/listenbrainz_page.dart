import 'package:auto_route/auto_route.dart';
import 'package:crossonic/ui/common/buttons.dart';
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
        title: const Text("ListenBrainz"),
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
            child: _viewModel.username == null
                ? _ConnectContent(
                    onConnect: (token) => _submit(context, token),
                    submitting: _viewModel.submitting,
                  )
                : _ConnectedContent(viewModel: _viewModel),
          );
        },
      ),
    );
  }

  Future<void> _submit(BuildContext context, String token) async {
    final result = await _viewModel.connect(token);
    if (!context.mounted) return;
    if (result is Err && result.error is! ConnectionException) {
      Toast.show(context, "Invalid token");
      return;
    }
    toastResult(context, result);
  }
}

class _ConnectedContent extends StatelessWidget {
  final ListenBrainzViewModel _viewModel;

  const _ConnectedContent({required ListenBrainzViewModel viewModel})
      : _viewModel = viewModel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        ListTile(
          title: Row(
            spacing: 4,
            children: [
              Text(
                "Connected:",
                style: textTheme.bodyMedium!
                    .copyWith(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Flexible(
                child: Text(_viewModel.username!,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium!.copyWith(fontSize: 14)),
              ),
            ],
          ),
        ),
        if (_viewModel.settingsSupported) const SizedBox(height: 8),
        if (_viewModel.settingsSupported)
          SwitchListTile(
            value: _viewModel.scrobbleEnabled,
            title: const Text("Enable scrobbling"),
            onChanged: (bool enable) async {
              final result =
                  await _viewModel.updateSettings(scrobbleEnabled: enable);
              if (!context.mounted) return;
              toastResult(context, result);
            },
          ),
        if (_viewModel.settingsSupported)
          SwitchListTile(
            value: _viewModel.syncFavorites,
            title: const Text("Enable favorites sync"),
            onChanged: (bool enable) async {
              final result =
                  await _viewModel.updateSettings(syncFavorites: enable);
              if (!context.mounted) return;
              toastResult(context, result);
            },
          ),
        const SizedBox(height: 25),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Button(
            onPressed: !_viewModel.submitting
                ? () async {
                    final result = await _viewModel.disconnect();
                    if (!context.mounted) return;
                    toastResult(context, result);
                  }
                : null,
            darkTonal: true,
            child: _viewModel.submitting
                ? const Text("Disconnecting…")
                : const Text("Disconnect"),
          ),
        ),
      ],
    );
  }
}

class _ConnectContent extends StatefulWidget {
  final void Function(String token) onConnect;
  final bool submitting;

  const _ConnectContent({required this.onConnect, required this.submitting});

  @override
  State<_ConnectContent> createState() => _ConnectContentState();
}

class _ConnectContentState extends State<_ConnectContent> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          FormBuilderTextField(
            name: "apiToken",
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            decoration: const InputDecoration(
              labelText: "API Token",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.key),
            ),
            validator: FormBuilderValidators.required(),
            onSubmitted: (value) {
              if (value == null) return;
              widget.onConnect(value);
            },
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Button(
              onPressed: !widget.submitting
                  ? () {
                      if (_formKey.currentState == null || widget.submitting) {
                        return;
                      }
                      if (!_formKey.currentState!.saveAndValidate()) {
                        return;
                      }
                      widget
                          .onConnect(_formKey.currentState!.value["apiToken"]);
                    }
                  : null,
              darkTonal: true,
              child: widget.submitting
                  ? const Text("Connecting…")
                  : const Text("Connect"),
            ),
          )
        ],
      ),
    );
  }
}
