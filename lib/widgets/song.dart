import 'package:crossonic/widgets/cover_art.dart';
import 'package:flutter/material.dart';

class Song extends StatelessWidget {
  final String title;
  final int? track;
  final String? coverID;
  final Duration? duration;
  final bool? isFavorite;
  final String? artist;
  final String? album;
  final int? year;
  final void Function()? onTap;
  const Song({
    super.key,
    required this.title,
    this.track,
    this.coverID,
    this.duration,
    this.isFavorite,
    this.onTap,
    this.artist,
    this.album,
    this.year,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      leading: track != null
          ? Text(
              track.toString().padLeft(2, '0'),
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            )
          : (coverID != null
              ? CoverArt(
                  size: 40,
                  coverID: coverID!,
                  resolution: const CoverResolution.tiny(),
                  borderRadius: BorderRadius.circular(5),
                )
              : null),
      title: Row(
        children: [
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.bodyMedium!
                    .copyWith(fontWeight: FontWeight.w400, fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
              if (artist != null || album != null || year != null)
                Text(
                  [
                    if (artist != null) artist,
                    if (album != null) album,
                    if (year != null) year.toString(),
                  ].join(" • "),
                  style: textTheme.bodySmall!
                      .copyWith(fontWeight: FontWeight.w300, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          )),
          if (isFavorite ?? false) const Icon(Icons.favorite, size: 15),
          if (duration != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '${duration!.inHours > 0 ? '${duration!.inHours}:' : ''}${duration!.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration!.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                style: textTheme.bodySmall,
              ),
            ),
        ],
      ),
      horizontalTitleGap: track != null ? 8 : null,
      trailing: IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () {},
      ),
      onTap: onTap,
    );
  }
}
