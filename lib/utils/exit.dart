import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

Future<void> exitApp() async {
  if (kIsWeb) return;
  if (Platform.isWindows) {
    // release build on windows freezes when calling windowManager.destroy()
    exit(0);
  }
  await windowManager.destroy();
  if (Platform.isMacOS) {
    exit(0);
  }
}
