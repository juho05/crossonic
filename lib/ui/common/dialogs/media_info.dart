import 'package:crossonic/ui/common/dialogs/media_info_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MediaInfoDialog extends StatelessWidget {
  const MediaInfoDialog._();

  static Future<void> showSong(BuildContext context, String id) async {
    await showAdaptiveDialog(
      context: context,
      builder: (context) {
        return ChangeNotifierProvider(
          create: (context) => MediaInfoDialogViewModel.song(
            subsonicService: context.read(),
            authRepository: context.read(),
            id: id,
          ),
          builder: (context, child) => const MediaInfoDialog._(),
        );
      },
    );
  }

  static Future<void> showAlbum(BuildContext context, String id) async {
    await showAdaptiveDialog(
      context: context,
      builder: (context) {
        return ChangeNotifierProvider(
          create: (context) => MediaInfoDialogViewModel.album(
            subsonicService: context.read(),
            authRepository: context.read(),
            id: id,
          ),
          builder: (context, child) => const MediaInfoDialog._(),
        );
      },
    );
  }

  static Future<void> showArtist(BuildContext context, String id) async {
    await showAdaptiveDialog(
      context: context,
      builder: (context) {
        return ChangeNotifierProvider(
          create: (context) => MediaInfoDialogViewModel.artist(
            subsonicService: context.read(),
            authRepository: context.read(),
            id: id,
          ),
          builder: (context, child) => const MediaInfoDialog._(),
        );
      },
    );
  }

  static Future<void> showPlaylist(BuildContext context, String id) async {
    await showAdaptiveDialog(
      context: context,
      builder: (context) {
        return ChangeNotifierProvider(
          create: (context) => MediaInfoDialogViewModel.playlist(
            subsonicService: context.read(),
            authRepository: context.read(),
            id: id,
          ),
          builder: (context, child) => const MediaInfoDialog._(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints.loose(const Size.fromWidth(600)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Consumer<MediaInfoDialogViewModel>(
              builder: (context, viewModel, _) {
                if (viewModel.status == FetchStatus.failure) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 50),
                      child: Icon(Icons.wifi_off),
                    ),
                  );
                }
                if (viewModel.status != FetchStatus.success) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 50),
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  );
                }
                return Column(
                  spacing: 8,
                  children: [
                    Text(
                      viewModel.name,
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 4,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    ...viewModel.fields.map(
                      (f) => Row(
                        spacing: 4,
                        children: [
                          Text(
                            "${f.$1}:",
                            style: textTheme.bodyMedium!
                                .copyWith(fontWeight: FontWeight.w800),
                          ),
                          Expanded(
                            child: SelectableText(
                              f.$2,
                              minLines: 1,
                              maxLines: 10,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Close"),
                    )
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
