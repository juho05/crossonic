import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

Future<void> exitApp() async {
  if (kIsWeb) return;
  await windowManager.setPreventClose(false);
  await windowManager.close();
  exit(0);
}
