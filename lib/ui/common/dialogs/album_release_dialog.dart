import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/ui/common/album_list_item.dart';
import 'package:crossonic/ui/common/clickable_list_item.dart';
import 'package:crossonic/ui/common/dialogs/album_release_viewmodel.dart';
import 'package:crossonic/ui/common/dialogs/dialog.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AlbumReleaseDialog extends StatelessWidget {
  const AlbumReleaseDialog._();

  static Future<void> show(
    BuildContext context, {
    required Album album,
    List<Album>? alternatives,
  }) async {
    await showAdaptiveDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return ChangeNotifierProvider(
          create: (context) => AlbumReleaseDialogViewModel(
            subsonicRepository: context.read(),
            album: album,
            alternatives: alternatives,
          ),
          builder: (context, child) => const AlbumReleaseDialog._(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return CrossonicDialog(
      child: ConstrainedBox(
        constraints: BoxConstraints.loose(const Size.fromWidth(450)),
        child: Consumer<AlbumReleaseDialogViewModel>(
          builder: (context, viewModel, _) {
            return Container(
              constraints: BoxConstraints(
                maxHeight:
                    194 +
                    viewModel.alternatives.length *
                        ClickableListItem.verticalExtent +
                    (viewModel.status != FetchStatus.success ||
                            viewModel.alternatives.isEmpty
                        ? ClickableListItem.verticalExtent
                        : 0),
              ),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 12,
                      top: 24,
                      bottom: 8,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        "Release Versions",
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverToBoxAdapter(
                      child: Text("Current", style: textTheme.titleMedium),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: AlbumListItem(
                      album: viewModel.album,
                      showArtist: false,
                      showReleaseVersion: true,
                      onNavigate: () => Navigator.of(context).pop(),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.only(left: 12, right: 12, top: 6),
                    sliver: SliverToBoxAdapter(
                      child: Text("Other", style: textTheme.titleMedium),
                    ),
                  ),
                  if (viewModel.alternatives.isNotEmpty)
                    SliverFixedExtentList.builder(
                      itemCount: viewModel.alternatives.length,
                      itemExtent: ClickableListItem.verticalExtent,
                      itemBuilder: (context, index) => AlbumListItem(
                        album: viewModel.alternatives[index],
                        showArtist: false,
                        showReleaseVersion: true,
                        onNavigate: () => Navigator.of(context).pop(),
                      ),
                    ),
                  if (viewModel.status == FetchStatus.loading)
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: ClickableListItem.verticalExtent,
                        child: Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      ),
                    ),
                  if (viewModel.status == FetchStatus.failure)
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: ClickableListItem.verticalExtent,
                        child: Center(child: Icon(Icons.wifi_off)),
                      ),
                    ),
                  if (viewModel.status == FetchStatus.success &&
                      viewModel.alternatives.isEmpty)
                    const SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      sliver: SliverToBoxAdapter(
                        child: SizedBox(
                          height: ClickableListItem.verticalExtent,
                          child: Center(
                            child: Text(
                              "No alternatives found",
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
