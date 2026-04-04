/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
import 'package:crossonic/ui/common/optional_tooltip.dart';
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
  final bool enabled;

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
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final textColor = !enabled ? theme.disabledColor : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final child = InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                ?leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OptionalTooltip(
                        message: title,
                        triggerOnLongPress: false,
                        child: Text(
                          title,
                          style: textTheme.bodyMedium!.copyWith(
                            fontSize: 15,
                            color: textColor,
                            fontWeight: titleBold
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (extraInfo.isNotEmpty ||
                          downloadStatus != DownloadStatus.none)
                        Row(
                          spacing: 2,
                          children: [
                            if (downloadStatus == DownloadStatus.downloaded)
                              Icon(
                                Icons.download_for_offline_outlined,
                                color: textColor ?? Theme.of(context).colorScheme.primary,
                                size: 15,
                              ),
                            if (downloadStatus == DownloadStatus.downloading)
                              Icon(
                                Icons.downloading_outlined,
                                color: textColor ?? Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                size: 15,
                              ),
                            if (downloadStatus == DownloadStatus.enqueued)
                              Icon(
                                Icons.schedule,
                                color: textColor ?? Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                size: 15,
                              ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: OptionalTooltip(
                                  message: extraInfo.join(" • "),
                                  triggerOnLongPress: false,
                                  child: Text(
                                    extraInfo.join(" • "),
                                    style: textTheme.bodySmall!.copyWith(
                                      fontWeight: FontWeight.w300,
                                      fontSize: 12,
                                      color: textColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                if (isFavorite)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.favorite, size: 15, color: textColor),
                  ),
                if (trailingInfo != null && constraints.maxWidth > 320)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      trailingInfo!,
                      style: textTheme.bodySmall!.copyWith(
                        color: textColor,
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
