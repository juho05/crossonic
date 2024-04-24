import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class Song extends StatelessWidget {
  final String id;
  final String title;
  final int? track;
  final String? coverURL;
  final Duration? duration;
  final bool? isFavorite;
  final void Function()? onTap;
  const Song({
    super.key,
    required this.id,
    required this.title,
    this.track,
    this.coverURL,
    this.duration,
    this.isFavorite,
    this.onTap,
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
          : (coverURL != null
              ? SizedBox(
                  width: 35,
                  height: 35,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    clipBehavior: Clip.antiAlias,
                    child: CachedNetworkImage(
                        imageUrl: coverURL!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const Icon(Icons.album, size: 30),
                        fadeInDuration: const Duration(milliseconds: 300),
                        fadeOutDuration: const Duration(milliseconds: 100),
                        errorWidget: (context, url, error) {
                          return const Icon(Icons.album, size: 30);
                        }),
                  ),
                )
              : null),
      title: Row(
        children: [
          Expanded(child: Text(title)),
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
