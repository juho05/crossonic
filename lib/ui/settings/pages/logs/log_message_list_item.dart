import 'package:crossonic/data/repositories/logger/log_message.dart';
import 'package:crossonic/utils/format.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class LogMessageListItem extends StatelessWidget {
  final LogMessage msg;

  static const double verticalExtent = 115;

  const LogMessageListItem({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    final color = _logLevelToColor(msg.level);
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
                // TODO
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
                        Text(
                          formatDateTime(msg.time),
                          style:
                              textStyle.copyWith(fontWeight: FontWeight.bold),
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

  Color _logLevelToColor(Level level) {
    return switch (level) {
      Level.trace || Level.verbose || Level.all => Colors.grey,
      Level.debug => Colors.green,
      Level.info => Colors.blue,
      Level.warning => Colors.amber,
      Level.error => Colors.red,
      Level.fatal ||
      Level.wtf ||
      Level.off ||
      Level.nothing =>
        Colors.purpleAccent,
    };
  }
}
