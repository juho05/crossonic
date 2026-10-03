/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:crossonic/data/repositories/cover/cover_image_provider.dart';
import 'package:crossonic/data/repositories/cover/cover_repository.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCoverRepository extends Mock implements CoverRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCoverRepository repository;

  setUp(() {
    repository = MockCoverRepository();
    PaintingBinding.instance.imageCache.clear();
  });

  Future<Object> resolveError(CoverImageProvider provider) {
    final completer = Completer<Object>();
    provider
        .resolve(ImageConfiguration.empty)
        .addListener(
          ImageStreamListener(
            (_, _) => completer.completeError("expected the load to fail"),
            onError: (error, _) => completer.complete(error),
          ),
        );
    return completer.future;
  }

  test("a failed load is evicted from the image cache and retried", () async {
    when(
      () => repository.loadCoverFile(any(), any()),
    ).thenThrow(Exception("offline"));
    final provider = CoverImageProvider(
      repository,
      coverId: "cover",
      resolution: 256,
    );

    await resolveError(provider);
    await Future.delayed(Duration.zero);

    expect(
      PaintingBinding.instance.imageCache.statusForKey(provider).untracked,
      isTrue,
    );

    await resolveError(provider);

    verify(() => repository.loadCoverFile("cover", 256)).called(2);
  });
}
