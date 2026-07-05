/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/services/methodchannel/method_channel_service.dart';
import 'package:flutter/foundation.dart';

// Android 17 (API 37) enforces the ACCESS_LOCAL_NETWORK runtime permission for
// any local network access (mDNS/NSD discovery, connecting to LAN devices).
// permission_handler does not support it yet, so it is requested via the native
// method channel, handled by the Activity.
class LocalNetworkPermission {
  final MethodChannelService _methodChannel;

  LocalNetworkPermission({required this._methodChannel});

  Future<bool> request() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final granted = await _methodChannel.invokeMethod<bool>(
        "requestLocalNetworkPermission",
      );
      return granted ?? false;
    } catch (e, st) {
      Log.warn("failed to request local network permission", e: e, st: st);
      return false;
    }
  }
}