import 'dart:io';

import 'package:crossonic/data/repositories/appimage/appimage_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:flutter/foundation.dart';

class Restart {
  static bool supported = !kIsWeb && AppImageRepository.isAppImage;

  static Future<void> restart() async {
    if (kIsWeb) return;

    if (AppImageRepository.isAppImage) {
      return _restartAppImage();
    }
    throw UnimplementedError("restarts are not supported on this platform");
  }

  static Future<void> _restartAppImage() async {
    Log.info("Restarting application...");

    Process.run("/bin/sh", [
      "-c",
      "/bin/sh -c \"sleep 1 && ${AppImageRepository.appImageFile.path}\" & disown"
    ]);

    Future.delayed(const Duration(milliseconds: 100), () => exit(0));
  }
}
