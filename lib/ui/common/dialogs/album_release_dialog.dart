import 'package:crossonic/data/repositories/subsonic/models/date.dart';
import 'package:crossonic/ui/common/dialogs/album_release_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AlbumReleaseDialog extends StatelessWidget {
  const AlbumReleaseDialog._();

  static Future<void> show(
    BuildContext context, {
    required String albumId,
    required String albumName,
    required Date? originalDate,
    required Date? releaseDate,
    required String? albumVersion,
  }) async {
    await showAdaptiveDialog(
      context: context,
      builder: (context) {
        return ChangeNotifierProvider(
          create: (context) => AlbumReleaseDialogViewModel(
            albumName: albumName,
            albumVersion: albumVersion,
            releaseDate: releaseDate,
            originalDate: originalDate,
          ),
          builder: (context, child) => const AlbumReleaseDialog._(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints.loose(const Size.fromWidth(450)),
        child: Consumer<AlbumReleaseDialogViewModel>(
            builder: (context, viewModel, _) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                spacing: 8,
                children: [
                  Text(
                    viewModel.albumName,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  if (viewModel.albumVersion != null)
                    Row(
                      spacing: 4,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Version:",
                          style: textTheme.bodyMedium!
                              .copyWith(fontWeight: FontWeight.w800),
                        ),
                        Flexible(
                          child: Text(
                            viewModel.albumVersion!,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  if (viewModel.releaseDate != null)
                    Row(
                      spacing: 4,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Released:",
                          style: textTheme.bodyMedium!
                              .copyWith(fontWeight: FontWeight.w800),
                        ),
                        Flexible(
                          child: Text(
                            viewModel.releaseDate.toString(),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  if (viewModel.originalDate != null)
                    Row(
                      spacing: 4,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Original release:",
                          style: textTheme.bodyMedium!
                              .copyWith(fontWeight: FontWeight.w800),
                        ),
                        Flexible(
                          child: Text(
                            viewModel.originalDate.toString(),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Close"),
                  )
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
