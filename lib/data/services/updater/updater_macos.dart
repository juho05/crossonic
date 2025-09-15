import 'dart:io';

import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/version/version.dart';
import 'package:crossonic/data/services/updater/updater.dart';
import 'package:crossonic/utils/exceptions.dart';
import 'package:crossonic/utils/result.dart';
import 'package:path/path.dart' as path;

class MacOSUpdateFailedException extends AppException {
  const MacOSUpdateFailedException(super.message);
}

class UpdaterMacOS implements Updater {
  static final volumeRegex = RegExp("\\/Volumes\\/(.*)\n");

  @override
  Future<String> generateDownloadFileName(Version version) async =>
      "Crossonic-$version-macOS-universal.dmg";

  @override
  Future<Result<void>> install(File downloadedFile) async {
    try {
      Log.debug("Mounting DMG ${downloadedFile.path}...");

      final dmgAttachResult = await Process.run(
          "hdiutil", ["attach", "-nobrowse", "-readonly", downloadedFile.path],
          stdoutEncoding: systemEncoding);
      throwOnNonZeroExitCode(dmgAttachResult);

      final dmgAttachOutput = dmgAttachResult.stdout as String;
      Match? match = volumeRegex.firstMatch(dmgAttachOutput);
      if (match == null) {
        return Result.error(MacOSUpdateFailedException(
            "failed to parse attach dmg output to determine volume:\n$dmgAttachOutput"));
      }
      String volumePath = "/Volumes/${match.group(1)!}";

      Process.run("/bin/zsh", [
        "-c",
        "/bin/zsh -c \"sleep 2 && cp -pPR \\\"${path.join(volumePath, "Crossonic.app")}\\\" /Applications/ && xattr -r -d com.apple.quarantine /Applications/Crossonic.app && sleep 1 && open /Applications/Crossonic.app; hdiutil detach \\\"$volumePath\\\"\" & disown"
      ]);
      await Future.delayed(const Duration(milliseconds: 250), () => exit(0));
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}
