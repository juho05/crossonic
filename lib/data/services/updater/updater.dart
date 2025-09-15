import 'dart:io';

import 'package:crossonic/data/repositories/version/version.dart';
import 'package:crossonic/utils/exceptions.dart';
import 'package:crossonic/utils/result.dart';

abstract class Updater {
  Future<String> generateDownloadFileName(Version version);

  Future<Result<void>> install(File downloadedFile);
}

class NonZeroExitException extends AppException {
  NonZeroExitException(ProcessResult result, dynamic errOut)
      : super("process exited with status code ${result.exitCode}: \n$errOut");
}

void throwOnNonZeroExitCode(ProcessResult result) {
  if (result.exitCode != 0) {
    throw NonZeroExitException(result, result.stderr);
  }
}
