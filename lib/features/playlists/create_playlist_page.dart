import 'package:crossonic/features/playlists/state/create_playlist_cubit.dart';
import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:crossonic/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/components/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CreatePlaylistPage extends StatefulWidget {
  const CreatePlaylistPage({super.key});

  @override
  State<CreatePlaylistPage> createState() => _CreatePlaylistPageState();
}

class _CreatePlaylistPageState extends State<CreatePlaylistPage>
    with RestorationMixin {
  final _nameController = RestorableTextEditingController();
  String _lastValue = "";

  CreatePlaylistCubit? cubit;

  void _updateName() {
    if (_nameController.value.text != _lastValue) {
      cubit?.nameChanged(_nameController.value.text);
      _lastValue = _nameController.value.text;
    }
  }

  _CreatePlaylistPageState() {
    _nameController.addListener(_updateName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createAppBar(context, "Create"),
      body: BlocProvider(
        create: (context) => CreatePlaylistCubit(context.read<APIRepository>()),
        child: BlocConsumer<CreatePlaylistCubit, CreatePlaylistState>(
          listener: (context, state) async {
            if (state.status == CreatePlaylistStatus.created) {
              await context.read<PlaylistRepository>().fetch();
              if (context.mounted) {
                context.pop();
              }
              return;
            }
            if (state.status != CreatePlaylistStatus.none) {
              final String? message;
              switch (state.status) {
                case CreatePlaylistStatus.connectionError:
                  message = 'Cannot connect to server';
                case CreatePlaylistStatus.unexpectedError:
                  message = 'An unexpected error occured';
                default:
                  message = null;
              }
              if (message != null) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(message)));
              }
            }
          },
          builder: (context, state) {
            cubit = context.read<CreatePlaylistCubit>();
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Playlist',
                      style: Theme.of(context).textTheme.displayMedium),
                  Expanded(
                    child: Align(
                      alignment: const Alignment(0, -1 / 3),
                      child: SizedBox(
                        width: 430,
                        child: AutofillGroup(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: _nameController.value,
                                decoration: InputDecoration(
                                  labelText: "Name",
                                  border: const OutlineInputBorder(),
                                  errorText: state.status !=
                                              CreatePlaylistStatus.initial &&
                                          state.name.isEmpty
                                      ? "Playlist name is required"
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _CreateButton(),
                  const SizedBox(height: 30),
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
    _nameController.dispose();
    super.dispose();
  }

  @override
  String? get restorationId => "create_playlist";

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_nameController, "create_playlist_name_controller");
  }
}

class _CreateButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreatePlaylistCubit, CreatePlaylistState>(
      builder: (context, state) {
        return state.status == CreatePlaylistStatus.loading
            ? const CircularProgressIndicator.adaptive()
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 20)),
                onPressed: state.name.isNotEmpty
                    ? () {
                        context.read<CreatePlaylistCubit>().submit();
                      }
                    : null,
                child: const Text('Create'),
              );
      },
    );
  }
}
