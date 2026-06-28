import 'package:crossonic/data/repositories/cover/cover_repository.dart';
import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/data/repositories/settings/logging.dart';
import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:crossonic/data/repositories/settings/workarounds.dart';
import 'package:crossonic/ui/settings/pages/debug_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockCoverRepository extends Mock implements CoverRepository {}

class MockPlaylistRepository extends Mock implements PlaylistRepository {}

class _FakeKeyValue extends Fake implements KeyValueRepository {
  @override
  Future<void> store<T>(String key, T value) async {}
  @override
  Future<void> remove(String key) async {}
  @override
  Future<String?> loadString(String key) async => null;
  @override
  Future<bool?> loadBool(String key) async => null;
}

void main() {
  late MockSettingsRepository settings;
  late LoggingSettings logging;
  late WorkaroundSettings workarounds;
  late MockCoverRepository coverRepo;
  late MockPlaylistRepository playlistRepo;

  setUp(() {
    settings = MockSettingsRepository();
    final kv = _FakeKeyValue();
    logging = LoggingSettings(keyValueRepository: kv);
    workarounds = WorkaroundSettings(keyValueRepository: kv);
    coverRepo = MockCoverRepository();
    playlistRepo = MockPlaylistRepository();

    when(() => settings.logging).thenReturn(logging);
    when(() => settings.workarounds).thenReturn(workarounds);
  });

  DebugViewModel buildViewModel() => DebugViewModel(
        settings: settings,
        coverRepo: coverRepo,
        playlistRepo: playlistRepo,
      );

  group('constructor', () {
    test('reads level and stopIsPause from settings', () {
      final vm = buildViewModel();
      expect(vm.level, logging.level);
      expect(vm.stopIsPause, workarounds.stopIsPause);
      vm.dispose();
    });
  });

  group('logging notification', () {
    test('logging change re-reads both fields and notifies', () {
      final vm = buildViewModel();
      var notifications = 0;
      vm.addListener(() => notifications++);

      logging.level = Level.warning;

      expect(vm.level, Level.warning);
      expect(notifications, greaterThanOrEqualTo(1));
      vm.dispose();
    });
  });

  group('workarounds notification', () {
    test('workarounds change re-reads both fields and notifies', () {
      final vm = buildViewModel();
      var notifications = 0;
      vm.addListener(() => notifications++);

      workarounds.stopIsPause = true;

      expect(vm.stopIsPause, isTrue);
      expect(notifications, greaterThanOrEqualTo(1));
      vm.dispose();
    });
  });

  group('level setter', () {
    test('sets level on underlying logging settings', () {
      final vm = buildViewModel();
      vm.level = Level.error;
      expect(logging.level, Level.error);
      vm.dispose();
    });
  });

  group('stopIsPause setter', () {
    test('sets stopIsPause on underlying workaround settings', () {
      final vm = buildViewModel();
      vm.stopIsPause = true;
      expect(workarounds.stopIsPause, isTrue);
      vm.dispose();
    });
  });

  group('resetWorkarounds', () {
    test('resets workarounds to defaults', () {
      workarounds.stopIsPause = true;
      final vm = buildViewModel();

      vm.resetWorkarounds();

      expect(workarounds.stopIsPause, isFalse);
      vm.dispose();
    });
  });

  group('clearCoverCache', () {
    test('calls emptyCache then downloadCovers in order', () async {
      var order = <String>[];
      when(() => coverRepo.emptyCache()).thenAnswer((_) async {
        order.add('emptyCache');
      });
      when(() => playlistRepo.downloadCovers()).thenAnswer((_) async {
        order.add('downloadCovers');
      });

      final vm = buildViewModel();
      await vm.clearCoverCache();

      expect(order, ['emptyCache', 'downloadCovers']);
      vm.dispose();
    });
  });

  group('dispose', () {
    test('removes listeners so changes no longer notify', () {
      final vm = buildViewModel();
      var notifications = 0;
      vm.addListener(() => notifications++);
      vm.dispose();

      logging.level = Level.fatal;
      workarounds.stopIsPause = true;

      expect(notifications, 0);
    });
  });
}
