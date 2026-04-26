/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:crossonic/data/repositories/audio/casting/device.dart';
import 'package:crossonic/data/repositories/audio/casting/device_discoverer.dart';
import 'package:crossonic/data/repositories/audio/casting/sonos/sonos_device.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:http/http.dart' as http;
import 'package:mdns_dart/mdns_dart.dart';
import 'package:xml/xml.dart';

class SonosDiscoverer extends DeviceDiscoverer {
  final _http = http.Client();

  Timer? _discoveryTimer;

  bool _queryRunning = false;

  @override
  Future<void> startDiscovery() async {
    if (_discoveryTimer != null) return;

    if (_queryRunning) {
      await Future.delayed(const Duration(seconds: 1));
      return startDiscovery();
    }

    Log.debug("discovering sonos devices...");
    _discoverDevices().then((value) {
      if (_discoveryTimer != null) return;
      _discoveryTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
        await _discoverDevices();
      });
    });
  }

  Future<void> _discoverDevices() async {
    _queryRunning = true;
    try {
      final stream = await MDNSClient.query(
        QueryParams(
          service: "_sonos._tcp",
          timeout: const Duration(seconds: 5),
        ),
      );
      await for (final entry in stream) {
        final ipAddr = entry.addrsV4?.firstOrNull?.address;
        if (ipAddr == null) return;
        Log.debug(
          "found sonos device at $ipAddr: ${entry.name}, loading device info...",
        );
        final device = await _loadDeviceInfo(ipAddr);
        if (device != null) {
          Log.debug(
            "new valid sonos device: ${device.name} (${(device as SonosDevice).ipAddr})",
          );
          discoveredController.add(device);
        }
      }
    } finally {
      _queryRunning = false;
    }
  }

  @override
  Future<void> stopDiscovery() async {
    _discoveryTimer?.cancel();
    _discoveryTimer = null;
  }

  Future<Device?> _loadDeviceInfo(String ipAddr) async {
    try {
      final req = await _http
          .get(
            Uri(
              scheme: "http",
              host: ipAddr,
              port: 1400,
              pathSegments: ["xml", "device_description.xml"],
            ),
            headers: {"Connection": "close"},
          )
          .timeout(const Duration(seconds: 3));

      final xml = XmlDocument.parse(req.body);

      final root = xml.findElements("root").firstOrNull;
      if (root == null) {
        Log.warn(
          "Response from sonos device $ipAddr has invalid structure: missing root element: $xml",
        );
        return null;
      }

      final device = root.findElements("device").firstOrNull;
      if (device == null) {
        Log.warn(
          "Response from sonos device $ipAddr has invalid structure: missing device element: $xml",
        );
        return null;
      }

      final modelName =
          (device.findElements("displayName").firstOrNull ??
                  device.findElements("modelName").firstOrNull)
              ?.firstChild
              ?.value;

      final nameElement = device.findElements("roomName").firstOrNull;
      final name =
          (nameElement?.firstChild?.value ?? modelName) ?? "Sonos device";

      final mediaRenderer = device
          .findElements("deviceList")
          .firstOrNull
          ?.findElements("device")
          .where(
            (d) =>
                d.findElements("deviceType").firstOrNull?.firstChild?.value ==
                "urn:schemas-upnp-org:device:MediaRenderer:1",
          )
          .firstOrNull;
      if (mediaRenderer == null) {
        Log.debug("Sonos device $ipAddr is not a media renderer");
        return null;
      }

      final mediaRendererServices =
          mediaRenderer
              .findElements("serviceList")
              .firstOrNull
              ?.findElements("service") ??
          [];

      final avTransport = mediaRendererServices
          .where(
            (s) =>
                s.findElements("serviceType").firstOrNull?.firstChild?.value ==
                "urn:schemas-upnp-org:service:AVTransport:1",
          )
          .firstOrNull;
      if (avTransport == null) {
        Log.debug("Sonos device $ipAddr has no AVTransport service");
        return null;
      }

      final avTransportPath = avTransport
          .findElements("controlURL")
          .firstOrNull
          ?.firstChild
          ?.value;
      if (avTransportPath == null) {
        Log.debug("Sonos device $ipAddr has no AVTransport control URL");
        return null;
      }

      final renderingControl = mediaRendererServices
          .where(
            (s) =>
                s.findElements("serviceType").firstOrNull?.firstChild?.value ==
                "urn:schemas-upnp-org:service:RenderingControl:1",
          )
          .firstOrNull;
      if (renderingControl == null) {
        Log.debug("Sonos device $ipAddr has no RenderingControl service");
        return null;
      }

      final renderingControlPath = renderingControl
          .findElements("controlURL")
          .firstOrNull
          ?.firstChild
          ?.value;
      if (renderingControlPath == null) {
        Log.debug("Sonos device $ipAddr has no RenderingControl control URL");
        return null;
      }

      return SonosDevice(
        name: name,
        ipAddr: ipAddr,
        modelName: modelName,
        avTransportControlPath: avTransportPath,
        renderingControlPath: renderingControlPath,
      );
    } catch (e, st) {
      Log.warn(
        "failed to load device info of sonos device at $ipAddr",
        e: e,
        st: st,
      );
    }
    return null;
  }
}
