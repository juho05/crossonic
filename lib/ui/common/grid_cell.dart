import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
import 'package:crossonic/ui/common/cover_art_decorated.dart';
import 'package:crossonic/ui/common/optional_tooltip.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:flutter/material.dart';

class GridCell extends StatelessWidget {
  final Iterable<ContextMenuOption> menuOptions;
  final bool circularCover;
  final bool isFavorite;
  final IconData placeholderIcon;
  final String? coverId;
  final String title;
  late final String extraInfo;
  final void Function()? onTap;
  final DownloadStatus downloadStatus;

  final Widget? topLeft;
  final Widget? topRight;
  final Widget? bottomLeft;
  final Widget? bottomRight;

  GridCell({
    super.key,
    required this.title,
    required this.menuOptions,
    required this.coverId,
    required this.placeholderIcon,
    this.onTap,
    Iterable<String> extraInfo = const [],
    this.circularCover = false,
    this.isFavorite = false,
    this.downloadStatus = DownloadStatus.none,
    this.topLeft,
    this.topRight,
    this.bottomLeft,
    this.bottomRight,
  }) {
    this.extraInfo = extraInfo.join(" • ");
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return WithContextMenu(
      options: menuOptions,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
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
                menuOptions: menuOptions,
                bottomLeft: bottomLeft,
                bottomRight: bottomRight,
                topLeft: topLeft,
                topRight: topRight,
              ),
              const SizedBox(height: 2),
              OptionalTooltip(
                message: title,
                triggerOnLongPress: false,
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
              ),
              OptionalTooltip(
                message: extraInfo,
                triggerOnLongPress: false,
                child: Text(
                  extraInfo,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w300,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
