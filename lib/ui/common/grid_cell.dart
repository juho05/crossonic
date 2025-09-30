import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
import 'package:crossonic/ui/common/cover_art_decorated.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GridCell extends StatelessWidget {
  final Iterable<ContextMenuOption> menuOptions;
  final bool circularCover;
  final bool isFavorite;
  final IconData placeholderIcon;
  final String? coverId;
  final String title;
  final Iterable<String> extraInfo;
  final void Function()? onTap;
  final DownloadStatus downloadStatus;

  final Widget? topLeft;
  final Widget? topRight;
  final Widget? bottomLeft;
  final Widget? bottomRight;

  const GridCell({
    super.key,
    required this.title,
    required this.menuOptions,
    required this.coverId,
    required this.placeholderIcon,
    this.onTap,
    this.extraInfo = const [],
    this.circularCover = false,
    this.isFavorite = false,
    this.downloadStatus = DownloadStatus.none,
    this.topLeft,
    this.topRight,
    this.bottomLeft,
    this.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return WithContextMenu(
      options: menuOptions,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CoverArtDecorated(
                      borderRadius: circularCover
                          ? BorderRadius.circular(99999)
                          : BorderRadius.circular(7),
                      isFavorite: isFavorite,
                      placeholderIcon: placeholderIcon,
                      coverId: coverId,
                      downloadStatus: downloadStatus,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize:
                            (constraints.maxHeight * 0.07).clamp(10, 13.5),
                      ),
                    ),
                    Text(
                      extraInfo.join(" • "),
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w300,
                        fontSize: (constraints.maxHeight * 0.06).clamp(9, 11),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
              ),
            ),
          ),
          AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Provider<OnCoverIconButtonSize>.value(
                    value: constraints.maxHeight >= 256
                        ? OnCoverIconButtonSize.large
                        : OnCoverIconButtonSize.normal,
                    builder: (context, _) {
                      final size = context.read<OnCoverIconButtonSize>();
                      final largeLayout = size == OnCoverIconButtonSize.large;
                      return Padding(
                        padding: EdgeInsets.all(largeLayout ? 10 : 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Visibility(
                                  visible: topLeft != null,
                                  child: topLeft ?? const SizedBox.shrink(),
                                ),
                                Visibility(
                                  visible: topRight != null,
                                  child: topRight ?? const SizedBox.shrink(),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Visibility(
                                  visible: bottomLeft != null,
                                  child: bottomLeft ?? const SizedBox.shrink(),
                                ),
                                Visibility(
                                  visible: menuOptions.isNotEmpty ||
                                      bottomRight != null,
                                  child: bottomRight ??
                                      OnCoverMenuButton(
                                        menuOptions: menuOptions,
                                      ),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    });
              },
            ),
          )
        ],
      ),
    );
  }
}
