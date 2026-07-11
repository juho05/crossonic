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

  // Requests the permission only when the target actually lives on the local
  // network, so connecting to a remote server does not trigger a prompt.
  // On iOS the system shows its own prompt on first local network access, so
  // nothing needs to be requested manually here.
  Future<bool> requestIfLocal(Uri uri) async {
    if (kIsWeb || !Platform.isAndroid) return true;
    if (!await targetsLocalNetwork(uri)) return true;
    return request();
  }

  static Future<bool> targetsLocalNetwork(Uri uri) async {
    final host = uri.host;
    if (host.isEmpty) return false;
    if (host.toLowerCase().endsWith(".local")) return true;

    final literal = InternetAddress.tryParse(host);
    if (literal != null) return _isPrivate(literal);

    try {
      final addresses = await InternetAddress.lookup(
        host,
      ).timeout(const Duration(seconds: 3), onTimeout: () => const []);
      return addresses.any(_isPrivate);
    } catch (_) {
      return false;
    }
  }

  static bool _isPrivate(InternetAddress addr) {
    // Loopback stays on the device itself and does not need the permission.
    if (addr.isLoopback) return false;
    if (addr.isLinkLocal) return true;

    final bytes = addr.rawAddress;
    if (addr.type == InternetAddressType.IPv4) {
      final b0 = bytes[0];
      final b1 = bytes[1];
      if (b0 == 10) return true;
      if (b0 == 172 && b1 >= 16 && b1 <= 31) return true;
      if (b0 == 192 && b1 == 168) return true;
      // 100.64.0.0/10 carrier-grade NAT, used by e.g. Tailscale
      if (b0 == 100 && b1 >= 64 && b1 <= 127) return true;
      return false;
    }

    // IPv6: fc00::/7 unique local addresses
    return (bytes[0] & 0xfe) == 0xfc;
  }
}