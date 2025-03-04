import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/settings/replay_gain.dart';
import 'package:crossonic/ui/settings/pages/replay_gain_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';

@RoutePage()
class ReplayGainPage extends StatefulWidget {
  const ReplayGainPage({super.key});

  @override
  State<ReplayGainPage> createState() => _ReplayGainState();
}

class _ReplayGainState extends State<ReplayGainPage> {
  late final ReplayGainViewModel _viewModel;
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    _viewModel = ReplayGainViewModel(settings: context.read());
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
        title: Text("Replay Gain"),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          _formKey.currentState?.fields["mode"]?.didChange(_viewModel.mode);
          _formKey.currentState?.fields["fallbackGain"]
              ?.didChange(_viewModel.fallbackGain.toString());
          _formKey.currentState?.fields["preferServerFallback"]
              ?.didChange(_viewModel.preferServerFallback);
          return Padding(
            padding: const EdgeInsets.all(8),
            child: FormBuilder(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                spacing: 10,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  FormBuilderField<ReplayGainMode>(
                    name: "mode",
                    validator: FormBuilderValidators.required(),
                    initialValue: _viewModel.mode,
                    builder: (field) {
                      return DropdownMenu<ReplayGainMode>(
                        onSelected: (mode) {
                          field.didChange(mode);
                          _submit();
                        },
                        expandedInsets: EdgeInsets.zero,
                        requestFocusOnTap: false,
                        enableSearch: false,
                        initialSelection: field.value,
                        label: const Text("Replay Gain Mode"),
                        dropdownMenuEntries: ReplayGainMode.values.map((mode) {
                          return DropdownMenuEntry<ReplayGainMode>(
                            label: mode.name,
                            value: mode,
                          );
                        }).toList(),
                      );
                    },
                  ),
                  FormBuilderSwitch(
                    name: "preferServerFallback",
                    title: Text("Prefer server fallback gain"),
                    validator: FormBuilderValidators.required(),
                    onChanged: (value) => _submit(),
                    initialValue: _viewModel.preferServerFallback,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                    ),
                  ),
                  FormBuilderTextField(
                    name: "fallbackGain",
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: "Fallback Gain (dB)",
                      border: const OutlineInputBorder(),
                    ),
                    onTapOutside: (event) {
                      _submit();
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    initialValue: _viewModel.fallbackGain.toString(),
                    onSubmitted: (value) => _submit(),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.numeric(),
                      FormBuilderValidators.negativeNumber(
                          errorText:
                              "A positive replay gain may cause clipping"),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  ElevatedButton.icon(
                    onPressed: () {
                      _viewModel.reset();
                    },
                    icon: Icon(Icons.settings_backup_restore),
                    label: Text("Reset"),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _submit() {
    final valid = _formKey.currentState?.saveAndValidate(
            focusOnInvalid: false, autoScrollWhenFocusOnInvalid: false) ??
        false;
    if (!valid) return;
    final values = _formKey.currentState!.value;
    _viewModel.update(
      mode: values["mode"],
      fallbackGain: double.parse(values["fallbackGain"]),
      preferServerFallback: values["preferServerFallback"],
    );
  }
}
