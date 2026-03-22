/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:crossonic/data/repositories/appimage/appimage_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/version/version.dart';
import 'package:crossonic/data/services/updater/updater.dart';
import 'package:crossonic/utils/result.dart';

class UpdaterLinuxAppImage implements Updater {
  @override
  Future<String> generateDownloadFileName(Version version) async =>
      "Crossonic-$version-linux-x86-64.AppImage";

  @override
  Future<Result<void>> install(File downloadedFile) async {
    try {
      // delete existing file first to prevent "Text file busy" error
      await AppImageRepository.appImageFile.delete();
      await downloadedFile.copy(AppImageRepository.appImageFile.path);

      try {
        await Process.run("chmod", [
          "+x",
          AppImageRepository.appImageFile.path,
        ], runInShell: true);
      } on Exception catch (e, st) {
        Log.error("Failed to make updated AppImage executable", e: e, st: st);
      }

      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}
