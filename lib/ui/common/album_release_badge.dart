import 'package:crossonic/data/repositories/subsonic/models/date.dart';
import 'package:flutter/material.dart';

class AlbumReleaseBadge extends StatelessWidget {
  final String albumId;
  final Date releaseDate;
  final String? albumVersion;

  const AlbumReleaseBadge({
    super.key,
    required this.albumId,
    required this.releaseDate,
    required this.albumVersion,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final backgroundColor = Colors.blue.shade900;
    final foregroundColor = Colors.white;
    return Container(
      decoration: BoxDecoration(
          color: backgroundColor.withAlpha(200),
          border: Border.all(color: backgroundColor),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              offset: const Offset(2, 2),
              blurRadius: 6,
            ),
          ]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Material(
          type: MaterialType.transparency,
          child: Tooltip(
            message: albumVersion ?? "${releaseDate.year} release",
            child: InkWell(
              onTap: () {
                // TODO
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                child: Text(releaseDate.year.toString(),
                    style: textTheme.bodyMedium!
                        .copyWith(color: foregroundColor, fontSize: 12)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
