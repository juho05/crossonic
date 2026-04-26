/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:convert';

import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/services/upnp/upnp_connection.dart';
import 'package:crossonic/data/services/upnp/upnp_mediaitem.dart';
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
    final xmlContent =
        '<InstanceID>0</InstanceID>\n'
        '<NextURI>${mediaItem?.url ?? ""}</NextURI>\n'
        '<NextURIMetaData>${mediaItem?.metadataXml() ?? ""}</NextURIMetaData>';
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
      xmlContent: xmlContent,
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

  Future<Result<void>> _request({
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
      // TODO handle response
      Log.debug("Upnp response [$method]:\n${response.body}");
      return const Result.ok(null);
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
}
