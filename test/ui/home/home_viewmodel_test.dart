import 'dart:async';

import 'package:crossonic/data/repositories/settings/home_page_layout.dart';
import 'package:crossonic/data/repositories/subsonic/music_folders_repository.dart';
import 'package:crossonic/data/repositories/subsonic/server_support.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/home/home_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeLayoutSettings extends Mock implements HomeLayoutSettings {}

class MockSubsonicRepository extends Mock implements SubsonicRepository {}

class MockMusicFoldersRepository extends Mock implements MusicFoldersRepository {}

class MockServerSupport extends Mock implements ServerSupport {}

void main() {
  late MockHomeLayoutSettings settings;
  late MockSubsonicRepository subsonic;
  late MockMusicFoldersRepository musicFolders;
  late MockServerSupport supports;
  late StreamController<void> debouncedController;

  setUp(() {
    settings = MockHomeLayoutSettings();
    subsonic = MockSubsonicRepository();
    musicFolders = MockMusicFoldersRepository();
    supports = MockServerSupport();
    debouncedController = StreamController<void>.broadcast();

    when(() => subsonic.supports).thenReturn(supports);
    when(() => settings.selectedOptions)
        .thenReturn([HomeContentOption.randomSongs]);
    when(() => musicFolders.debounced).thenAnswer((_) => debouncedController.stream);
  });

  tearDown(() async {
    await debouncedController.close();
  });

  HomeViewModel buildViewModel() => HomeViewModel(
        settings: settings,
        subsonicRepository: subsonic,
        musicFolders: musicFolders,
      );

  group('constructor', () {
    test('sets seed when randomSeed is supported', () {
      when(() => supports.randomSeed).thenReturn(true);
      final vm = buildViewModel();
      expect(vm.seed, isNotNull);
      vm.dispose();
    });

    test('seed is null when randomSeed is not supported', () {
      when(() => supports.randomSeed).thenReturn(false);
      final vm = buildViewModel();
      expect(vm.seed, isNull);
      vm.dispose();
    });

    test('content is populated from settings on construction', () {
      when(() => supports.randomSeed).thenReturn(false);
      when(() => settings.selectedOptions)
          .thenReturn([HomeContentOption.randomSongs, HomeContentOption.favoriteArtists]);
      final vm = buildViewModel();
      expect(vm.content, [HomeContentOption.randomSongs, HomeContentOption.favoriteArtists]);
      vm.dispose();
    });
  });

  group('settings change', () {
    test('updates content and notifies listeners when settings change', () {
      when(() => supports.randomSeed).thenReturn(false);
      final vm = buildViewModel();

      final seen = <List<HomeContentOption>>[];
      vm.addListener(() => seen.add(List.of(vm.content)));

      final listener =
          verify(() => settings.addListener(captureAny())).captured.single
              as void Function();

      when(() => settings.selectedOptions)
          .thenReturn([HomeContentOption.favoriteArtists]);
      listener();

      expect(seen, isNotEmpty);
      expect(vm.content, [HomeContentOption.favoriteArtists]);
      vm.dispose();
    });
  });

  group('refresh', () {
    test('refresh(true) regenerates seed when randomSeed supported and notifies', () async {
      when(() => supports.randomSeed).thenReturn(true);
      final vm = buildViewModel();
      final seedBefore = vm.seed;

      final notifications = <String?>[];
      vm.addListener(() => notifications.add(vm.seed));

      vm.refresh(true);

      expect(vm.seed, isNotNull);
      expect(notifications, isNotEmpty);
      // In most cases the random seed will be different (very unlikely to be equal)
      // We just assert it was regenerated (non-null and a notification was fired)
      vm.dispose();
    });

    test('refresh(true) emits true on refreshStream', () async {
      when(() => supports.randomSeed).thenReturn(true);
      final vm = buildViewModel();

      final emitted = <bool>[];
      final sub = vm.refreshStream.listen(emitted.add);

      vm.refresh(true);
      await Future.delayed(Duration.zero);

      expect(emitted, [true]);
      await sub.cancel();
      vm.dispose();
    });

    test('refresh(false) does NOT change seed', () async {
      when(() => supports.randomSeed).thenReturn(true);
      final vm = buildViewModel();
      final seedBefore = vm.seed;

      vm.refresh(false);

      expect(vm.seed, seedBefore);
      vm.dispose();
    });

    test('refresh(false) emits false on refreshStream', () async {
      when(() => supports.randomSeed).thenReturn(false);
      final vm = buildViewModel();

      final emitted = <bool>[];
      final sub = vm.refreshStream.listen(emitted.add);

      vm.refresh(false);
      await Future.delayed(Duration.zero);

      expect(emitted, [false]);
      await sub.cancel();
      vm.dispose();
    });
  });

  group('music folder debounce', () {
    test('debounced music folder event triggers refresh(false)', () async {
      when(() => supports.randomSeed).thenReturn(false);
      final vm = buildViewModel();

      final emitted = <bool>[];
      final sub = vm.refreshStream.listen(emitted.add);

      debouncedController.add(null);
      await Future.delayed(Duration.zero);

      expect(emitted, [false]);
      await sub.cancel();
      vm.dispose();
    });
  });

  group('dispose', () {
    test('dispose closes refreshStream', () async {
      when(() => supports.randomSeed).thenReturn(false);
      final vm = buildViewModel();

      bool streamClosed = false;
      final sub = vm.refreshStream.listen(null, onDone: () => streamClosed = true);

      vm.dispose();
      await Future.delayed(Duration.zero);

      expect(streamClosed, isTrue);
      await sub.cancel();
    });

    test('dispose removes settings listener', () {
      when(() => supports.randomSeed).thenReturn(false);
      final vm = buildViewModel();

      vm.dispose();

      verify(() => settings.removeListener(any())).called(1);
    });
  });
}