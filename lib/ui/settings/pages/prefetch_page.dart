/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:auto_route/auto_route.dart';
import 'package:crossonic/ui/settings/pages/prefetch_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';

@RoutePage()
class PrefetchPage extends StatefulWidget {
  const PrefetchPage({super.key});

  @override
  State<PrefetchPage> createState() => _PrefetchPageState();
}

class _PrefetchPageState extends State<PrefetchPage> {
  late final PrefetchViewModel _viewModel;
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    _viewModel = PrefetchViewModel(settings: context.read());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Prefetch")),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          _formKey.currentState?.fields["count"]?.didChange(
            _viewModel.count.toString(),
          );
          return Padding(
            padding: const EdgeInsets.all(8),
            child: FormBuilder(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                spacing: 12,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text("Enable prefetching"),
                    value: _viewModel.enabled,
                    onChanged: (value) => _viewModel.enabled = value,
                  ),
                  if (_viewModel.enabled)
                    FormBuilderTextField(
                      name: "count",
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Number of songs to prefetch",
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _viewModel.count.toString(),
                      onTapOutside: (event) {
                        _submitCount();
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      onSubmitted: (value) => _submitCount(),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.integer(),
                        FormBuilderValidators.min(
                          _viewModel.minCount,
                          errorText: "Must be at least ${_viewModel.minCount}",
                        ),
                      ]),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _submitCount() {
    final field = _formKey.currentState?.fields["count"];
    if (field == null) return;
    if (!field.validate()) return;
    final value = int.tryParse(field.value as String? ?? "");
    if (value == null) return;
    _viewModel.count = value;
  }
}
