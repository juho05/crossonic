import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/playlists/create/create_playlist_viewmodel.dart';
import 'package:crossonic/utils/result.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';

@RoutePage()
class CreatePlaylistPage extends StatefulWidget {
  const CreatePlaylistPage({
    super.key,
  });

  @override
  State<CreatePlaylistPage> createState() => _CreatePlaylistPageState();
}

class _CreatePlaylistPageState extends State<CreatePlaylistPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  late final CreatePlaylistViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CreatePlaylistViewModel(playlistRepository: context.read());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    flex: 2,
                    child: Text("Playlist",
                        style: Theme.of(context).textTheme.displayMedium),
                  ),
                  Expanded(
                    flex: 3,
                    child: FormBuilderTextField(
                      name: "name",
                      restorationId: "create_playlist_name",
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: "Name",
                        icon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                      validator: FormBuilderValidators.required(),
                      onSubmitted: (_) => _submit(context),
                    ),
                  ),
                  ListenableBuilder(
                    listenable: _viewModel,
                    builder: (context, _) => ElevatedButton(
                      onPressed:
                          !_viewModel.loading ? () => _submit(context) : null,
                      style: ButtonStyle(),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text("Create"),
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
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (_formKey.currentState == null || _viewModel.loading) {
      return;
    }
    if (!_formKey.currentState!.saveAndValidate()) {
      return;
    }
    final result =
        await _viewModel.create(_formKey.currentState!.value["name"]);
    if (context.mounted) {
      switch (result) {
        case Err():
          toastResult(context, result);
        case Ok():
          context.router.replace(PlaylistRoute(playlistId: result.value));
      }
    }
  }
}
