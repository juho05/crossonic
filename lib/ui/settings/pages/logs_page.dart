import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

@RoutePage()
class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TalkerScreen(
      talker: Log.talker,
      isLogsExpanded: false,
      isLogOrderReversed: true,
      appBarTitle: "Logs",
      theme: TalkerScreenTheme.fromTheme(Theme.of(context)),
    );
  }
}
