/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/utils/exceptions.dart';

enum SubsonicErrorCode {
  generic(0),
  missingRequiredParam(10),
  outdatedClient(20),
  outdatedServer(30),
  incorrectCredentials(40),
  tokenAuthNotSupported(41),
  authMechanismNotSupported(42),
  conflictingAuthParams(43),
  invalidAPIKey(44),
  userNotAuthorized(50),
  trialEnded(60),
  notFound(70),
  unknown(-1);

  const SubsonicErrorCode(this.code);
  final int code;

  static SubsonicErrorCode fromCode(int code) {
    for (var c in SubsonicErrorCode.values) {
      if (c.code == code) {
        return c;
      }
    }
    return SubsonicErrorCode.unknown;
  }
}

class SubsonicException extends UnexpectedResponseException {
  final SubsonicErrorCode code;
  const SubsonicException(this.code, super.message);
  @override
  String toString() {
    return "SubsonicException (${code.code}: ${code.toString()}): $message";
  }
}
