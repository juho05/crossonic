import 'package:crossonic/data/repositories/subsonic/models/date.dart';
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
        child: Tooltip(
          message: releaseDate == null
              ? "$alternativeCount other version${alternativeCount != 1 ? "s" : ""}"
              : "${(albumVersion ?? "${releaseDate?.year} release")}${alternativeCount != null && alternativeCount! > 0 ? " + $alternativeCount other version${alternativeCount != 1 ? "s" : ""}" : ""}",
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
