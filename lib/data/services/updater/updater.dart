import 'dart:io';

import 'package:crossonic/data/repositories/version/version.dart';
import 'package:crossonic/utils/result.dart';

abstract class Updater {
  Future<String> generateDownloadFileName(Version version);

  Future<Result<void>> install(File downloadedFile);
}
