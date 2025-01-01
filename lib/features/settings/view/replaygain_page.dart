import 'package:crossonic/features/settings/state/replay_gain_cubit.dart';
import 'package:crossonic/repositories/settings/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReplayGainPage extends StatefulWidget {
  const ReplayGainPage({super.key});

  @override
  State<ReplayGainPage> createState() => _ReplayGainPageState();
}

class _ReplayGainPageState extends State<ReplayGainPage> {
  final TextEditingController _fallbackGainController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crossonic | Replay Gain'),
      ),
      body: BlocProvider(
        create: (context) => ReplayGainCubit(context.read<Settings>()),
        child: BlocBuilder<ReplayGainCubit, ReplayGainState>(
          builder: (context, state) {
            final cubit = context.read<ReplayGainCubit>();
            _fallbackGainController.text = state.fallbackGain;
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  DropdownMenu<ReplayGainMode>(
                    onSelected: (mode) {
                      if (mode == null) return;
                      cubit.modeChanged(mode);
                    },
                    expandedInsets: EdgeInsets.zero,
                    initialSelection: state.mode,
                    requestFocusOnTap: false,
                    enableSearch: false,
                    label: const Text("Replay Gain Mode"),
                    dropdownMenuEntries: ReplayGainMode.values.map((mode) {
                      return DropdownMenuEntry<ReplayGainMode>(
                        label: mode.name,
                        value: mode,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                          child: Text("Prefer server fallback gain")),
                      Switch(
                        value: state.preferServerFallback,
                        onChanged: (value) {
                          cubit.preferServerFallbackChanged(value);
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _fallbackGainController,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: "Fallback Gain (dB)",
                      border: const OutlineInputBorder(),
                      errorText: state.fallbackError.isNotEmpty
                          ? state.fallbackError
                          : null,
                    ),
                    onTapOutside: (event) {
                      cubit.fallbackGainChanged(_fallbackGainController.text);
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    onSubmitted: (value) {
                      cubit.fallbackGainChanged(value);
                    },
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
