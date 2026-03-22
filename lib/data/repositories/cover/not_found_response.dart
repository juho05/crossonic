/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class NotFoundResponse extends FileServiceResponse {
  @override
  Stream<List<int>> get content => const Stream.empty();

  @override
  int? get contentLength => 0;

  @override
  String? get eTag => null;

  @override
  String get fileExtension => ".file";

  @override
  int get statusCode => 404;

  @override
  DateTime get validTill => DateTime.now();
}
