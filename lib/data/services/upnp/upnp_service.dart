/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:convert';

import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/services/upnp/exceptions.dart';
import 'package:crossonic/data/services/upnp/upnp_connection.dart';
import 'package:crossonic/data/services/upnp/upnp_mediaitem.dart';
import 'package:crossonic/data/services/upnp/upnp_position_info.dart';
import 'package:crossonic/data/services/upnp/upnp_transport_info.dart';
import 'package:crossonic/utils/result.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class UpnpService {
  static const _avTransportService =
      "urn:schemas-upnp-org:service:AVTransport:1";

  final _http = http.Client();

  Future<Result<void>> setMediaItem(
    UpnpConnection con,
    UpnpMediaItem mediaItem,
  ) async {
    final xmlBuilder = XmlBuilder();
    xmlBuilder.element(
      "InstanceID",
      nest: () {
        xmlBuilder.text("0");
      },
    );
    xmlBuilder.element(
      "CurrentURI",
      nest: () {
        xmlBuilder.text(mediaItem.url);
      },
    );
    xmlBuilder.element(
      "CurrentURIMetaData",
      nest: () {
        xmlBuilder.text(mediaItem.metadataXml());
      },
    );
    return await _request(
      uri: con.avTransportControlUri,
      method: "SetAVTransportURI",
      service: _avTransportService,
      xmlContent: xmlBuilder.buildDocument().toXmlString(),
    );
  }

  Future<Result<void>> setNextMediaItem(
    UpnpConnection con,
    UpnpMediaItem? mediaItem,
  ) async {
    final xmlBuilder = XmlBuilder();
    xmlBuilder.element(
      "InstanceID",
      nest: () {
        xmlBuilder.text("0");
      },
    );
    xmlBuilder.element(
      "NextURI",
      nest: () {
        if (mediaItem != null) {
          xmlBuilder.text(mediaItem.url);
        }
      },
    );
    xmlBuilder.element(
      "NextURIMetaData",
      nest: () {
        if (mediaItem != null) {
          xmlBuilder.text(mediaItem.metadataXml());
        }
      },
    );
    return await _request(
      uri: con.avTransportControlUri,
      method: "SetNextAVTransportURI",
      service: _avTransportService,
      xmlContent: xmlBuilder.buildDocument().toXmlString(),
    );
  }

  Future<Result<void>> play(UpnpConnection con) async {
    final xmlContent =
        '<InstanceID>0</InstanceID>\n'
        '<Speed>1</Speed>';
    return await _request(
      uri: con.avTransportControlUri,
      service: _avTransportService,
      method: "Play",
      xmlContent: xmlContent,
    );
  }

  Future<Result<void>> pause(UpnpConnection con) async {
    final xmlContent = '<InstanceID>0</InstanceID>';
    return await _request(
      uri: con.avTransportControlUri,
      service: _avTransportService,
      method: "Pause",
      xmlContent: xmlContent,
    );
  }

  Future<Result<void>> stop(UpnpConnection con) async {
    final xmlContent = '<InstanceID>0</InstanceID>';
    return await _request(
      uri: con.avTransportControlUri,
      service: _avTransportService,
      method: "Stop",
      xmlContent: xmlContent,
    );
  }

  Future<Result<UpnpTransportInfo>> getTransportInfo(UpnpConnection con) async {
    final xmlContent = '<InstanceID>0</InstanceID>';
    final result = await _request(
      uri: con.avTransportControlUri,
      service: _avTransportService,
      method: "GetTransportInfo",
      xmlContent: xmlContent,
    );
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    final body = result.value;
    final state = body
        ?.findElements("CurrentTransportState")
        .firstOrNull
        ?.firstChild
        ?.value;
    if (state == null) {
      return Result.error(UnexpectedUpnpResponse(body));
    }
    final status = body
        ?.findElements("CurrentTransportStatus")
        .firstOrNull
        ?.firstChild
        ?.value;
    final currentSpeedStr = body
        ?.findElements("CurrentSpeed")
        .firstOrNull
        ?.firstChild
        ?.value;
    double speed = 1;
    if (currentSpeedStr != null) {
      speed = double.parse(currentSpeedStr);
    }

    return Result.ok(
      UpnpTransportInfo(
        state: switch (state.toLowerCase()) {
          "stopped" => UpnpTransportState.stopped,
          "playing" => UpnpTransportState.playing,
          "paused_playback" => UpnpTransportState.pausedPlayback,
          "transitioning" => UpnpTransportState.transitioning,
          _ => UpnpTransportState.unknown,
        },
        status: status,
        speed: speed,
      ),
    );
  }

  Future<Result<UpnpPositionInfo>> getPositionInfo(UpnpConnection con) async {
    final start = DateTime.now();

    final xmlContent = '<InstanceID>0</InstanceID>';
    final result = await _request(
      uri: con.avTransportControlUri,
      service: _avTransportService,
      method: "GetPositionInfo",
      xmlContent: xmlContent,
    );
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    final body = result.value;
    final track = body?.findElements("Track").firstOrNull?.firstChild?.value;
    final trackDuration = parseDuration(
      body?.findElements("TrackDuration").firstOrNull?.firstChild?.value,
    );
    final trackUri = body
        ?.findElements("TrackURI")
        .firstOrNull
        ?.firstChild
        ?.value;
    final position = parseDuration(
      body?.findElements("RelTime").firstOrNull?.firstChild?.value,
    );

    if (track == null ||
        trackDuration == null ||
        trackUri == null ||
        position == null) {
      return Result.error(UnexpectedUpnpResponse(body));
    }

    final delay = DateTime.now().difference(start) * 0.5;

    return Result.ok(
      UpnpPositionInfo(
        track: int.parse(track),
        trackUri: trackUri,
        trackDuration: trackDuration,
        pos: position + delay,
        approximateTime: DateTime.now().subtract(delay),
      ),
    );
  }

  Future<Result<XmlElement?>> _request({
    required Uri uri,
    required String service,
    required String method,
    required String xmlContent,
  }) async {
    final xmlBody =
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">\n'
        '  <s:Body>\n'
        '    <u:$method xmlns:u="$service">\n'
        '      $xmlContent\n'
        '    </u:$method>\n'
        '  </s:Body>\n'
        '</s:Envelope>';

    // TODO sanitize urls
    Log.debug("Upnp request [$method]:\n$xmlBody");
    try {
      final response = await _http
          .post(
            uri,
            body: xmlBody,
            encoding: utf8,
            headers: {
              "soapaction": "$service#$method",
              "Content-Type": 'text/xml; charset="utf-8"',
              "charset": "utf-8",
              "Connection": "close",
            },
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode >= 300) {
        return Result.error(
          UpnpError(
            "unsuccessful soap request: ${response.statusCode}\n${response.body}",
          ),
        );
      }
      // TODO sanitize urls
      Log.debug("Upnp response [$method]:\n${response.body}");

      final responseXml = XmlDocument.parse(response.body);

      final responseElement = responseXml
          .findElements("s:Envelope")
          .firstOrNull
          ?.findElements("s:Body")
          .firstOrNull
          ?.findElements("u:${method}Response")
          .firstOrNull;

      if (responseElement == null) {
        Log.warn(
          "couldn't find response element in sonos response for $method:\n${response.body}",
        );
      }

      return Result.ok(responseElement);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  static String formatTime(Duration duration) {
    var seconds = duration.inSeconds;
    final hours = seconds ~/ 3600;
    seconds %= 3600;
    final minutes = seconds ~/ 60;
    seconds %= 60;

    return "${hours.toString().padLeft(2, "0")}:${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}";
  }

  static Duration? parseDuration(String? duration) {
    if (duration == null) return null;
    final parts = duration.split(":");
    if (parts.length < 2 || parts.length > 3) {
      throw FormatException("invalid duration: $duration");
    }
    return Duration(
      seconds: int.parse(parts[parts.length - 1]),
      minutes: int.parse(parts[parts.length - 2]),
      hours: parts.length == 3 ? int.parse(parts[0]) : 0,
    );
  }
}
