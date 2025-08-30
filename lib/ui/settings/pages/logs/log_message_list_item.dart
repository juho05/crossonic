import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/logger/log_message.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/settings/pages/logs/log_colors.dart';
import 'package:crossonic/utils/format.dart';
import 'package:flutter/material.dart';

class LogMessageListItem extends StatelessWidget {
  final LogMessage msg;

  static const double verticalExtent = 115;

  const LogMessageListItem({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    final color = levelColors[msg.level]!;
    final textStyle =
        Theme.of(context).textTheme.bodyMedium!.copyWith(color: color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        height: verticalExtent - 8,
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () {
                context.pushRoute(LogDetailsRoute(msg: msg));
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        Text(
                          msg.level.name.toUpperCase(),
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: Text(
                            formatDateTime(msg.time),
                            style:
                                textStyle.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (msg.exception != null)
                          Icon(
                            Icons.error_outline,
                            color: color,
                            size: 20,
                          )
                      ],
                    ),
                    Text(
                      msg.tag,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle.copyWith(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      msg.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle.copyWith(fontSize: 13),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
