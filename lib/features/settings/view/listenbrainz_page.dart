import 'package:crossonic/features/settings/state/listen_brainz_cubit.dart';
import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListenBrainzPage extends StatefulWidget {
  const ListenBrainzPage({super.key});

  @override
  State<ListenBrainzPage> createState() => _ListenBrainzPageState();
}

class _ListenBrainzPageState extends State<ListenBrainzPage>
    with RestorationMixin {
  final _controller = RestorableTextEditingController();
  String _lastValue = "";

  ListenBrainzCubit? cubit;

  void _updateValue() {
    if (_controller.value.text != _lastValue) {
      cubit?.tokenChanged(_controller.value.text);
      _lastValue = _controller.value.text;
    }
  }

  _ListenBrainzPageState() {
    _controller.addListener(_updateValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crossonic | ListenBrainz'),
      ),
      body: BlocProvider(
        create: (context) =>
            ListenBrainzCubit(apiRepository: context.read<APIRepository>()),
        child: BlocBuilder<ListenBrainzCubit, ListenBrainzState>(
          builder: (context, state) {
            cubit = context.read<ListenBrainzCubit>();
            if (state.status == ListenBrainzStatus.loadingConfig) {
              return const Center(
                child: CircularProgressIndicator.adaptive(),
              );
            }
            if (state.status == ListenBrainzStatus.configLoadError &&
                state.errorText.isEmpty) {
              return const Center(
                child: Icon(Icons.wifi_off),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  if (state.listenBrainzUsername.isNotEmpty)
                    Text("Connected: ${state.listenBrainzUsername}")
                  else
                    TextField(
                      controller: _controller.value,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: "API Token",
                        border: const OutlineInputBorder(),
                        icon: const Icon(Icons.key),
                        errorText:
                            state.errorText.isNotEmpty ? state.errorText : null,
                      ),
                    ),
                  const SizedBox(height: 15),
                  if (state.listenBrainzUsername.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 38),
                      child: ElevatedButton(
                        child: state.status == ListenBrainzStatus.submitting
                            ? const Text("Connecting…")
                            : const Text("Connect"),
                        onPressed: () {
                          if (state.status != ListenBrainzStatus.submitting) {
                            cubit?.connect();
                          }
                        },
                      ),
                    )
                  else
                    ElevatedButton(
                      child: const Text("Disconnect"),
                      onPressed: () {
                        cubit?.disconnect();
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  String? get restorationId => "settings_listenbrainz";

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_controller, "settings_listenbrainz_controller");
  }
}
