/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/settings/appearance.dart';
import 'package:crossonic/data/repositories/settings/home_page_layout.dart';
import 'package:crossonic/data/repositories/settings/logging.dart';
import 'package:crossonic/data/repositories/settings/replay_gain.dart';
import 'package:crossonic/data/repositories/settings/transcoding.dart';
import 'package:crossonic/data/repositories/settings/version_checking.dart';
import 'package:crossonic/data/repositories/settings/workarounds.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';

class SettingsRepository {
  final LoggingSettings logging;
  final ReplayGainSettings replayGain;
  final TranscodingSettings transcoding;
  final HomeLayoutSettings homeLayout;
  final AppearanceSettings appearanceSettings;
  final WorkaroundSettings workarounds;
  final VersionCheckingSettings versionChecking;

  SettingsRepository({
    required AuthRepository authRepository,
    required KeyValueRepository keyValueRepository,
    required SubsonicRepository subsonic,
  }) : logging = LoggingSettings(keyValueRepository: keyValueRepository),
       replayGain = ReplayGainSettings(keyValueRepository: keyValueRepository),
       transcoding = TranscodingSettings(
         keyValueRepository: keyValueRepository,
         subsonicRepository: subsonic,
       ),
       homeLayout = HomeLayoutSettings(keyValueRepository: keyValueRepository),
       appearanceSettings = AppearanceSettings(
         keyValueRepository: keyValueRepository,
       ),
       workarounds = WorkaroundSettings(keyValueRepository: keyValueRepository),
       versionChecking = VersionCheckingSettings(
         keyValueRepository: keyValueRepository,
       ) {
    bool wasAuthenticated = authRepository.isAuthenticated;
    authRepository.addListener(() {
      if (authRepository.isAuthenticated) {
        load();
      } else if (wasAuthenticated) {
        logging.level = logging.level;
        Log.debug("sign-out detected, restoring log level ${logging.level}");
      }
      wasAuthenticated = authRepository.isAuthenticated;
    });
  }

  Future<void> load() async {
    Log.debug("loading settings from db");
    await logging.load();
    await Future.wait([
      replayGain.load(),
      transcoding.load(),
      homeLayout.load(),
      appearanceSettings.load(),
      workarounds.load(),
      versionChecking.load(),
    ]);
  }

  void dispose() {
    replayGain.dispose();
    transcoding.dispose();
    homeLayout.dispose();
    appearanceSettings.dispose();
    workarounds.dispose();
    versionChecking.dispose();
    logging.dispose();
  }
}
