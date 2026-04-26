/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/services/upnp/upnp_service.dart';
import 'package:xml/xml.dart';

class UpnpMediaItem {
  final String url;

  final String title;
  final String contentType;
  final bool seekable;
  final Duration? duration;

  const UpnpMediaItem({
    required this.url,
    required this.title,
    required this.contentType,
    required this.seekable,
    required this.duration,
  });

  String metadataXml() {
    String contentFeatures = "";
    if (contentType == "audio/mpeg") {
      contentFeatures += "DLNA.ORG_PN=MP3;";
    }

    if (seekable) {
      contentFeatures += "DLNA.ORG_OP=01;";
    } else {
      contentFeatures += "DLNA.ORG_OP=00;";
    }

    contentFeatures +=
        "DLNA.ORG_CI=0;DLNA.ORG_FLAGS=01700000000000000000000000000000";

    final XmlBuilder builder = XmlBuilder();
    builder.element(
      "DIDL-Lite",
      attributes: {
        "xmlns": "urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/",
        "xmlns:dc": "http://purl.org/dc/elements/1.1/",
        "xmlns:sec": "http://www.sec.co.kr/",
        "xmlns:upnp": "urn:schemas-upnp-org:metadata-1-0/upnp/",
      },
      nest: () {
        builder.element(
          "item",
          attributes: {"id": "1", "parentID": "0", "restricted": "1"},
          nest: () {
            builder.element(
              "dc:title",
              nest: () {
                builder.text(title);
              },
            );
            builder.element(
              "upnp:class",
              nest: () {
                builder.text("object.item.audioItem.musicTrack");
              },
            );
            builder.element(
              "res",
              nest: () {
                builder.element(
                  "res",
                  attributes: {
                    if (duration != null)
                      "duration": UpnpService.formatTime(duration!),
                    "protocolInfo": "http-get:*:$contentType:$contentFeatures",
                  },
                  nest: () {
                    builder.text(url);
                  },
                );
              },
            );
          },
        );
      },
    );

    return builder.buildDocument().toXmlString();
  }
}
