/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

abstract class SubsonicAuth {
  Map<String, String> get queryParams;
  Map<String, String> get queryParamsCacheFriendly => queryParams;
}

class EmptyAuth extends SubsonicAuth {
  @override
  Map<String, String> get queryParams => {};
}

class Connection {
  final Uri baseUri;
  final SubsonicAuth auth;
  final bool supportsPost;

  const Connection({
    required this.baseUri,
    required this.auth,
    required this.supportsPost,
  });
}
