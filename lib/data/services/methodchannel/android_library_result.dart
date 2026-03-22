/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/services/methodchannel/android_mediaitem.dart';

enum AndroidLibraryResultCode {
  success(0),
  unknown(-1);

  final int value;
  const AndroidLibraryResultCode(this.value);
}

class AndroidLibraryResult {
  final AndroidLibraryResultCode resultCode;
  final AndroidLibraryParams params;
  final AndroidMediaItem? mediaItem;
  final List<AndroidMediaItem>? mediaItems;

  const AndroidLibraryResult({
    this.resultCode = AndroidLibraryResultCode.success,
    this.params = const AndroidLibraryParams(),
    this.mediaItem,
    this.mediaItems,
  });

  Map<String, dynamic> toMsgData() {
    return {
      "resultCode": resultCode.value,
      "params": params.toMsgData(),
      if (mediaItem != null) "mediaItem": mediaItem!.toMsgData(),
      if (mediaItems != null)
        "mediaItems": mediaItems!.map((m) => m.toMsgData()).toList(),
    };
  }
}

class AndroidLibraryParams {
  final bool isOffline;
  final bool isRecent;
  final bool isSuggested;

  const AndroidLibraryParams({
    this.isOffline = false,
    this.isRecent = false,
    this.isSuggested = false,
  });

  AndroidLibraryParams.fromMsgData(Map<Object?, dynamic>? data)
    : isOffline = data?["isOffline"] ?? false,
      isRecent = data?["isRecent"] ?? false,
      isSuggested = data?["isSuggested"] ?? false;

  Map<String, dynamic> toMsgData() {
    return {
      "isOffline": isOffline,
      "isRecent": isRecent,
      "isSuggested": isSuggested,
    };
  }
}
