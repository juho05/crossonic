/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/utils/exceptions.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

void toastResult(
  BuildContext context,
  Result result, {
  String? successMsg,
  bool logError = true,
}) {
  if (result is Err) {
    if (logError) {
      Log.error("error result", e: result.error, tag: "Toast");
    }
    if (context.mounted) {
      switch (result.error) {
        case ConnectionException():
          Toast.show(context, "Failed to contact server");
        default:
          Toast.show(context, "An unexpected error occured");
      }
    }
  } else if (successMsg != null && context.mounted) {
    Toast.show(context, successMsg);
  }
}
