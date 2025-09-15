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

    Process.run("/bin/bash", [
      "-c",
      "/bin/bash -c \"sleep 2 && ${AppImageRepository.appImageFile.path.replaceAll(" ", "\\ ")}\" & disown"
    ]);

    await Future.delayed(const Duration(milliseconds: 250), () => exit(0));
  }
}
