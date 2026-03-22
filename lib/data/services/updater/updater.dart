/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

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
