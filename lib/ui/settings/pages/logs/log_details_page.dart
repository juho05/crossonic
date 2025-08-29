import 'package:auto_route/annotations.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/logger/log_message.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/ui/settings/pages/logs/colors.dart';
import 'package:crossonic/utils/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

@RoutePage()
class LogDetailsPage extends StatelessWidget {
  final LogMessage msg;

  const LogDetailsPage({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Message Details"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Text(
                msg.level.name.toUpperCase(),
                style: textStyle.copyWith(
                  color: levelColors[msg.level],
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              LogMessageDetailsField(
                  label: "Time", content: formatDateTime(msg.time)),
              LogMessageDetailsField(label: "Tag", content: msg.tag),
              LogMessageDetailsField(label: "Message", content: msg.message),
              if (msg.exception != null)
                LogMessageDetailsField(
                    label: "Exception", content: msg.exception!),
              LogMessageDetailsField(
                  label: "Stack Trace", content: msg.stackTrace),
              LogMessageDetailsField(
                  label: "Session",
                  content: formatDateTime(msg.sessionStartTime)),
            ],
          ),
        ),
      ),
    );
  }
}

class LogMessageDetailsField extends StatelessWidget {
  final String label;
  final String content;

  const LogMessageDetailsField(
      {super.key, required this.label, required this.content});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: content,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          onPressed: () async {
            try {
              await Clipboard.setData(ClipboardData(text: content));
              if (!context.mounted) return;
              Toast.show(context, "Copied ${label.toLowerCase()}!");
            } catch (e, st) {
              Log.error(
                  "failed to add log message field ($label) content to clipboard",
                  e: e,
                  st: st);
              if (!context.mounted) return;
              Toast.show(context, "Failed to copy ${label.toLowerCase()}!");
            }
          },
          icon: const Icon(Icons.copy),
        ),
      ),
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 14),
      readOnly: true,
      minLines: 1,
      maxLines: 15,
    );
  }
}
