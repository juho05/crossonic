import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
import 'package:crossonic/ui/common/cover_art_decorated.dart';
import 'package:crossonic/ui/common/menu_button.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:flutter/material.dart';

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
            child: LayoutBuilder(builder: (context, constraints) {
              final largeLayout = constraints.maxHeight > 256;
              return Padding(
                padding: EdgeInsets.all(4 + (largeLayout ? 10 : 6)),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Ink(
                      decoration: ShapeDecoration(
                        color: Colors.black.withAlpha(90),
                        shape: const CircleBorder(),
                      ),
                      child: SizedBox(
                        width: largeLayout ? 40 : 30,
                        height: largeLayout ? 40 : 30,
                        child: MenuButton(
                          options: menuOptions,
                          padding: const EdgeInsets.all(0),
                          icon: Icon(
                            Icons.more_vert,
                            size: largeLayout ? 26 : 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
