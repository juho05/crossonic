import 'dart:io';

import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/version/version.dart';
import 'package:crossonic/data/services/updater/updater.dart';
import 'package:crossonic/utils/result.dart';

class UpdaterWindows implements Updater {
  @override
  Future<String> generateDownloadFileName(Version version) async =>
      "Crossonic-$version-windows-x86-64.exe";

  @override
  Future<Result<void>> install(File downloadedFile) async {
    try {
      Log.debug("Running installer ${downloadedFile.path}...");
      Process.run("powershell", ["-Command", "Start-Sleep -Seconds 2; &'${downloadedFile.absolute.path}' /SP-"]);
      await Future.delayed(const Duration(seconds: 1), () => exit(0));
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}
