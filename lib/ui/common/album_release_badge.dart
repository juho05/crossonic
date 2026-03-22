/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/subsonic/models/date.dart';
import 'package:crossonic/ui/common/optional_tooltip.dart';
import 'package:flutter/material.dart';

class AlbumReleaseBadge extends StatelessWidget {
  final String albumId;
  final Date? releaseDate;
  final String? albumVersion;
  final int? alternativeCount;
  final void Function()? onTap;

  const AlbumReleaseBadge({
    super.key,
    required this.albumId,
    required this.releaseDate,
    required this.albumVersion,
    this.alternativeCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final backgroundColor = Colors.blue.shade900;
    final foregroundColor = Colors.white;
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: OptionalTooltip(
          message: releaseDate == null
              ? "$alternativeCount other version${alternativeCount != 1 ? "s" : ""}"
              : "${(albumVersion ?? "${releaseDate?.year} release")}${alternativeCount != null && alternativeCount! > 0 ? " + $alternativeCount other version${alternativeCount != 1 ? "s" : ""}" : ""}",
          enableDelay: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            child: Text(
              "${releaseDate?.year.toString() ?? "null"}${alternativeCount != null && alternativeCount! > 0 ? " +$alternativeCount" : ""}",
              style: textTheme.bodyMedium!.copyWith(
                color: foregroundColor,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
