import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
import 'package:flutter/material.dart';

class ClickableListItem extends StatelessWidget {
  static const double verticalExtent = 52;

  final String title;
  final bool titleBold;
  final Iterable<String> extraInfo;
  final Widget? leading;
  final Widget? trailing;
  final String? trailingInfo;
  final void Function()? onTap;
  final bool isFavorite;
  final DownloadStatus downloadStatus;
  final bool opaque;

  const ClickableListItem({
    super.key,
    required this.title,
    this.titleBold = false,
    this.extraInfo = const [],
    this.leading,
    this.trailing,
    this.trailingInfo,
    this.onTap,
    this.isFavorite = false,
    this.downloadStatus = DownloadStatus.none,
    this.opaque = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final child = InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                if (leading != null) leading!,
                if (leading != null) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: textTheme.bodyMedium!.copyWith(
                          fontSize: 15,
                          fontWeight: titleBold
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (extraInfo.isNotEmpty ||
                          downloadStatus != DownloadStatus.none)
                        Row(
                          spacing: 2,
                          children: [
                            if (downloadStatus == DownloadStatus.downloaded)
                              Icon(
                                Icons.download_for_offline_outlined,
                                color: Theme.of(context).colorScheme.primary,
                                size: 15,
                              ),
                            if (downloadStatus == DownloadStatus.downloading)
                              Icon(
                                Icons.downloading_outlined,
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                size: 15,
                              ),
                            if (downloadStatus == DownloadStatus.enqueued)
                              Icon(
                                Icons.schedule,
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                size: 15,
                              ),
                            Expanded(
                              child: Text(
                                extraInfo.join(" • "),
                                style: textTheme.bodySmall!.copyWith(
                                  fontWeight: FontWeight.w300,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                if (isFavorite)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.favorite, size: 15),
                  ),
                if (trailingInfo != null && constraints.maxWidth > 320)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      trailingInfo!,
                      style: textTheme.bodySmall!.copyWith(
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                if (trailing != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: trailing!,
                  ),
              ],
            ),
          ),
        );
        return SizedBox(
          height: verticalExtent,
          child: opaque ? Material(child: child) : child,
        );
      },
    );
  }
}
