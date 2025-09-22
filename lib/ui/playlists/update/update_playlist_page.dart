import 'package:auto_route/auto_route.dart';
import 'package:crossonic/ui/common/buttons.dart';
import 'package:crossonic/ui/common/form_page_body.dart';
import 'package:crossonic/ui/playlists/update/update_playlist_viewmodel.dart';
import 'package:crossonic/utils/result.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';

@RoutePage()
class UpdatePlaylistPage extends StatefulWidget {
  final String playlistId;
  final String playlistName;
  final String playlistDescription;

  const UpdatePlaylistPage({
    super.key,
    @PathParam("id") required this.playlistId,
    this.playlistName = "",
    this.playlistDescription = "",
  });

  @override
  State<UpdatePlaylistPage> createState() => _UpdatePlaylistPageState();
}

class _UpdatePlaylistPageState extends State<UpdatePlaylistPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  late final UpdatePlaylistViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = UpdatePlaylistViewModel(
      playlistRepository: context.read(),
      playlistId: widget.playlistId,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: FormPageBody(
        formKey: _formKey,
        initialValues: {
          "name": widget.playlistName,
          "description": widget.playlistDescription,
        },
        children: [
          FormBuilderTextField(
            name: "name",
            restorationId: "update_playlist_name",
            decoration: const InputDecoration(
              labelText: "Name",
              prefixIcon: Icon(Icons.title),
              border: OutlineInputBorder(),
            ),
            validator: FormBuilderValidators.required(),
            onSubmitted: (_) => _submit(context),
          ),
          FormBuilderTextField(
            name: "description",
            restorationId: "create_playlist_description",
            decoration: const InputDecoration(
              labelText: "Description",
              prefixIcon: Icon(Icons.description_outlined),
              border: OutlineInputBorder(),
            ),
            minLines: 1,
            maxLines: 8,
            onSubmitted: (_) => _submit(context),
          ),
          SubmitButton(
            onPressed: !_viewModel.loading ? () => _submit(context) : null,
            child: const Text("Update"),
          ),
        ],
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
    final result = await _viewModel.update(_formKey.currentState!.value["name"],
        _formKey.currentState!.value["description"] ?? "");
    if (context.mounted) {
      switch (result) {
        case Err():
          toastResult(context, result);
        case Ok():
          context.router.back();
      }
    }
  }
}
