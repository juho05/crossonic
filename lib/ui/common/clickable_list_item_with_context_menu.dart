/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
import 'package:crossonic/ui/common/clickable_list_item.dart';
import 'package:crossonic/ui/common/menu_button.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:flutter/material.dart';

class ClickableListItemWithContextMenu extends StatelessWidget {
  final String title;
  final bool titleBold;
  final Iterable<String> extraInfo;
  final Widget? leading;
  final String? trailingInfo;
  final List<Widget>? extraTrailing;
  final void Function()? onTap;
  final bool isFavorite;
  final DownloadStatus downloadStatus;
  final Color? backgroundColor;
  final bool opaque;
  final bool contextMenuOnLongPress;

  final Iterable<ContextMenuOption> options;

  const ClickableListItemWithContextMenu({
    super.key,
    required this.title,
    required this.extraInfo,
    this.titleBold = false,
    this.leading,
    this.trailingInfo,
    this.onTap,
    this.options = const [],
    this.extraTrailing = const [],
    this.isFavorite = false,
    this.downloadStatus = DownloadStatus.none,
    this.backgroundColor,
    this.opaque = false,
    this.contextMenuOnLongPress = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClickableListItem(
      title: title,
      titleBold: titleBold,
      extraInfo: extraInfo,
      leading: leading,
      isFavorite: isFavorite,
      downloadStatus: downloadStatus,
      opaque: opaque,
      contextMenuOptions: options,
      contextMenuOnLongPress: contextMenuOnLongPress,
      trailing: options.isNotEmpty || extraTrailing != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (extraTrailing?.isNotEmpty ?? false)
                  Row(mainAxisSize: MainAxisSize.min, children: extraTrailing!),
                if (options.isNotEmpty) MenuButton(options: options),
              ],
            )
          : null,
      trailingInfo: trailingInfo,
      onTap: onTap,
    );
  }
}
