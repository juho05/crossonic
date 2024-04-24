import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Album extends StatelessWidget {
  final String id;
  final String name;
  final String extraInfo;
  final String? coverURL;
  const Album({
    super.key,
    required this.id,
    required this.name,
    required this.extraInfo,
    this.coverURL,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textTheme = Theme.of(context).textTheme;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              context.push("/home/album/$id");
            },
            child: SizedBox(
              width: constraints.maxHeight * (4 / 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: constraints.maxHeight * (4 / 5),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      clipBehavior: Clip.antiAlias,
                      child: coverURL != null
                          ? CachedNetworkImage(
                              imageUrl: coverURL!,
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 300),
                              fadeOutDuration:
                                  const Duration(milliseconds: 100),
                              placeholder: (context, url) => Icon(
                                Icons.album,
                                size: (constraints.maxHeight - 50) * 0.95,
                                opticalSize:
                                    (constraints.maxHeight - 50) * 0.95,
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.album,
                                size: (constraints.maxHeight - 50) * 0.95,
                                opticalSize:
                                    (constraints.maxHeight - 50) * 0.95,
                              ),
                            )
                          : Icon(
                              Icons.album,
                              size: (constraints.maxHeight - 50) * 0.95,
                              opticalSize: (constraints.maxHeight - 50) * 0.95,
                            ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: constraints.maxHeight * 0.07,
                    ),
                  ),
                  Text(
                    extraInfo,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w300,
                      fontSize: constraints.maxHeight * 0.06,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
