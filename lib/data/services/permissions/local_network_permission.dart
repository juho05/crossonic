/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:io';

import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

const _androidLocalNetworkPermissionSdk = 37;

int? _androidSdkInt;

// Android 17 (API 37) enforces the ACCESS_LOCAL_NETWORK runtime permission for
// any local network access (mDNS/NSD discovery, connecting to LAN devices).
// Android 16 only knows an opt-in variant of the restriction, guarded by
// NEARBY_WIFI_DEVICES, which we do not declare. Below that, local network
// access is implicitly granted via the INTERNET permission.
Future<bool> _isEnforced() async {
  if (kIsWeb || !Platform.isAndroid) return false;
  try {
    _androidSdkInt ??= (await DeviceInfoPlugin().androidInfo).version.sdkInt;
    return _androidSdkInt! >= _androidLocalNetworkPermissionSdk;
  } catch (e, st) {
    Log.warn("failed to determine android sdk version", e: e, st: st);
    return false;
  }
}

Future<bool>? _pendingRequest;

Future<bool> requestLocalNetworkPermission() async {
  if (!await _isEnforced()) return true;
  return _pendingRequest ??= _request().whenComplete(
    () => _pendingRequest = null,
  );
}

Future<bool> _request() async {
  try {
    return await Permission.accessLocalNetwork.request().isGranted;
  } catch (e, st) {
    Log.warn("failed to request local network permission", e: e, st: st);
    return false;
  }
}

// Requests the permission only when the target actually lives on the local
// network, so connecting to a remote server does not trigger a prompt.
// On iOS the system shows its own prompt on first local network access, so
// nothing needs to be requested manually here.
Future<bool> requestLocalNetworkPermissionIfLocal(Uri uri) async {
  if (!await _isEnforced()) return true;
  if (await _hasPermission()) return true;

  final host = uri.host;
  if (host.isEmpty) return true;

  final literal = InternetAddress.tryParse(host);
  if (literal != null) {
    return _isPrivate(literal) ? requestLocalNetworkPermission() : true;
  }
  if (host.toLowerCase().endsWith(".local")) {
    return requestLocalNetworkPermission();
  }

  // Resolving a hostname can be slow, so it must not delay the startup path.
  // Request the permission only once it is known to point at a local address.
  unawaited(_requestIfHostnameLocal(host));
  return true;
}

Future<bool> _hasPermission() async {
  try {
    return await Permission.accessLocalNetwork.isGranted;
  } catch (e, st) {
    Log.warn("failed to query local network permission", e: e, st: st);
    return false;
  }
}

Future<void> _requestIfHostnameLocal(String host) async {
  try {
    final addresses = await InternetAddress.lookup(host)
        .timeout(const Duration(milliseconds: 1500), onTimeout: () => const []);
    if (addresses.any(_isPrivate)) await requestLocalNetworkPermission();
  } catch (_) {}
}

bool _isPrivate(InternetAddress addr) {
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
