import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:crossonic/data/repositories/settings/version_checking.dart';
import 'package:crossonic/data/repositories/version/version.dart';
import 'package:crossonic/data/repositories/version/version_repository.dart';
import 'package:crossonic/utils/result.dart';
import 'package:crossonic/version_checker_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MockKeyValueRepository extends Mock implements KeyValueRepository {}

class MockVersionRepository extends Mock implements VersionRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockVersionCheckingSettings extends Mock
    implements VersionCheckingSettings {}

// Running version as set by PackageInfo mock: 1.2.3
const _current = Version(major: 1, minor: 2, patch: 3);
const _older = Version(major: 1, minor: 1, patch: 0);
const _newer = Version(major: 2, minor: 0, patch: 0);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    PackageInfo.setMockInitialValues(
      appName: 'crossonic',
      packageName: 'org.crossonic.app',
      version: '1.2.3',
      buildNumber: '1',
      buildSignature: '',
    );
    registerFallbackValue(const Version(major: 0));
    registerFallbackValue(DateTime.now());
  });

  late MockKeyValueRepository keyValue;
  late MockVersionRepository versionRepo;
  late MockSettingsRepository settings;
  late MockVersionCheckingSettings versionChecking;

  setUp(() {
    keyValue = MockKeyValueRepository();
    versionRepo = MockVersionRepository();
    settings = MockSettingsRepository();
    versionChecking = MockVersionCheckingSettings();

    when(() => versionChecking.enabled).thenReturn(true);
    when(() => settings.versionChecking).thenReturn(versionChecking);

    when(() => keyValue.loadObject<Version>(any(), any()))
        .thenAnswer((_) async => null);
    when(() => keyValue.loadDateTime(any())).thenAnswer((_) async => null);
    when(() => keyValue.loadString(any())).thenAnswer((_) async => null);
    when(() => keyValue.store<Version>(any(), any())).thenAnswer((_) async {});
    when(() => keyValue.store<DateTime>(any(), any())).thenAnswer((_) async {});
    when(() => keyValue.store<String>(any(), any())).thenAnswer((_) async {});
    when(() => keyValue.remove(any())).thenAnswer((_) async {});
  });

  VersionCheckerViewModel build() => VersionCheckerViewModel(
        keyValue: keyValue,
        versionRepo: versionRepo,
        settings: settings,
      );

  group('check disabled', () {
    test('settings disabled -> check() is a no-op', () async {
      when(() => versionChecking.enabled).thenReturn(false);
      final vm = build();

      await vm.check();

      verifyNever(() => versionRepo.getLatestVersion());
      expect(vm.latest, isNull);
      vm.dispose();
    });
  });

  group('upgrade detection', () {
    test('persisted current older than running -> showUpdateSuccessful + notify', () async {
      when(() => keyValue.loadObject<Version>(any(), any()))
          .thenAnswer((_) async => _older);
      when(() => keyValue.loadDateTime(any())).thenAnswer((_) async => null);
      when(() => versionRepo.getLatestVersion())
          .thenAnswer((_) async => const Result.ok(null));

      final vm = build();
      var notifications = 0;
      vm.addListener(() => notifications++);

      await vm.check();

      expect(vm.showUpdateSuccessful, isTrue);
      expect(notifications, greaterThanOrEqualTo(1));
      vm.dispose();
    });

    test('persisted current equal -> no banner', () async {
      when(() => keyValue.loadObject<Version>(any(), any()))
          .thenAnswer((_) async => _current);
      when(() => keyValue.loadDateTime(any())).thenAnswer((_) async => null);
      when(() => versionRepo.getLatestVersion())
          .thenAnswer((_) async => const Result.ok(null));

      final vm = build();
      await vm.check();

      expect(vm.showUpdateSuccessful, isFalse);
      vm.dispose();
    });
  });

  group('last-displayed throttle', () {
    test('displayed < 1 day ago -> getLatestVersion not called', () async {
      when(() => keyValue.loadObject<Version>(any(), any()))
          .thenAnswer((_) async => null);
      when(() => keyValue.loadDateTime(any()))
          .thenAnswer((_) async => DateTime.now().subtract(const Duration(hours: 12)));

      final vm = build();
      await vm.check();

      verifyNever(() => versionRepo.getLatestVersion());
      expect(vm.latest, isNull);
      vm.dispose();
    });

    test('displayed >= 1 day ago -> proceeds to fetch', () async {
      when(() => keyValue.loadObject<Version>(any(), any()))
          .thenAnswer((_) async => null);
      when(() => keyValue.loadDateTime(any()))
          .thenAnswer((_) async => DateTime.now().subtract(const Duration(days: 2)));
      when(() => versionRepo.getLatestVersion())
          .thenAnswer((_) async => const Result.ok(null));

      final vm = build();
      await vm.check();

      verify(() => versionRepo.getLatestVersion()).called(1);
      vm.dispose();
    });
  });

  group('latest version', () {
    setUp(() {
      when(() => keyValue.loadObject<Version>(any(), any()))
          .thenAnswer((_) async => null);
      when(() => keyValue.loadDateTime(any())).thenAnswer((_) async => null);
    });

    test('Err -> no latest, no notify', () async {
      when(() => versionRepo.getLatestVersion())
          .thenAnswer((_) async => Result.error(Exception('network')));

      final vm = build();
      var notifications = 0;
      vm.addListener(() => notifications++);

      await vm.check();

      expect(vm.latest, isNull);
      expect(notifications, 0);
      vm.dispose();
    });

    test('Ok(null) -> no latest, no notify', () async {
      when(() => versionRepo.getLatestVersion())
          .thenAnswer((_) async => const Result.ok(null));

      final vm = build();
      var notifications = 0;
      vm.addListener(() => notifications++);

      await vm.check();

      expect(vm.latest, isNull);
      expect(notifications, 0);
      vm.dispose();
    });

    test('latest > current -> sets latest + newVersionAvailable + notifies', () async {
      when(() => versionRepo.getLatestVersion())
          .thenAnswer((_) async => Result.ok(_newer));

      final vm = build();
      var notifications = 0;
      vm.addListener(() => notifications++);

      await vm.check();

      expect(vm.latest, _newer);
      expect(vm.newVersionAvailable, isTrue);
      expect(notifications, greaterThanOrEqualTo(1));
      vm.dispose();
    });

    test('latest <= current -> no notify, newVersionAvailable false', () async {
      when(() => versionRepo.getLatestVersion())
          .thenAnswer((_) async => Result.ok(_older));

      final vm = build();
      var notifications = 0;
      vm.addListener(() => notifications++);

      await vm.check();

      expect(vm.newVersionAvailable, isFalse);
      expect(notifications, 0);
      vm.dispose();
    });

    test('latest == ignore version -> no notify, ignore key not removed', () async {
      when(() => versionRepo.getLatestVersion())
          .thenAnswer((_) async => Result.ok(_newer));
      when(() => keyValue.loadString(any()))
          .thenAnswer((_) async => _newer.toString());

      final vm = build();
      var notifications = 0;
      vm.addListener(() => notifications++);

      await vm.check();

      expect(notifications, 0);
      verifyNever(() => keyValue.remove(any<String>()));
      vm.dispose();
    });

    test('latest != ignore version -> ignore key removed; if > current, notifies', () async {
      when(() => versionRepo.getLatestVersion())
          .thenAnswer((_) async => Result.ok(_newer));
      when(() => keyValue.loadString(any()))
          .thenAnswer((_) async => '0.9.0');

      final vm = build();
      var notifications = 0;
      vm.addListener(() => notifications++);

      await vm.check();

      verify(() => keyValue.remove(any())).called(1);
      expect(vm.latest, _newer);
      expect(notifications, greaterThanOrEqualTo(1));
      vm.dispose();
    });
  });

  group('idempotency', () {
    test('second check() is a no-op', () async {
      when(() => keyValue.loadObject<Version>(any(), any()))
          .thenAnswer((_) async => null);
      when(() => keyValue.loadDateTime(any())).thenAnswer((_) async => null);
      when(() => versionRepo.getLatestVersion())
          .thenAnswer((_) async => const Result.ok(null));

      final vm = build();
      await vm.check();
      await vm.check();

      verify(() => versionRepo.getLatestVersion()).called(1);
      vm.dispose();
    });
  });

  group('displayedVersionDialog', () {
    test('clears current and latest, stores timestamp', () async {
      when(() => keyValue.loadObject<Version>(any(), any()))
          .thenAnswer((_) async => null);
      when(() => keyValue.loadDateTime(any())).thenAnswer((_) async => null);
      when(() => versionRepo.getLatestVersion())
          .thenAnswer((_) async => Result.ok(_newer));

      final vm = build();
      await vm.check();
      expect(vm.latest, _newer);

      await vm.displayedVersionDialog();

      expect(vm.current, isNull);
      expect(vm.latest, isNull);
      verify(() => keyValue.store<DateTime>(any(), any())).called(greaterThanOrEqualTo(1));
      vm.dispose();
    });
  });

  group('ignoreVersion', () {
    test('no-op when latest is null', () async {
      when(() => keyValue.loadObject<Version>(any(), any()))
          .thenAnswer((_) async => null);
      when(() => keyValue.loadDateTime(any())).thenAnswer((_) async => null);
      when(() => versionRepo.getLatestVersion())
          .thenAnswer((_) async => const Result.ok(null));

      final vm = build();
      await vm.check();

      await vm.ignoreVersion();

      verifyNever(() => keyValue.store<String>(any(), any()));
      vm.dispose();
    });

    test('stores latest version string when latest set', () async {
      when(() => keyValue.loadObject<Version>(any(), any()))
          .thenAnswer((_) async => null);
      when(() => keyValue.loadDateTime(any())).thenAnswer((_) async => null);
      when(() => versionRepo.getLatestVersion())
          .thenAnswer((_) async => Result.ok(_newer));

      final vm = build();
      await vm.check();
      clearInteractions(keyValue);

      await vm.ignoreVersion();

      final stored = verify(() => keyValue.store<String>(any(), captureAny()))
          .captured;
      expect(stored, contains(_newer.toString()));
      vm.dispose();
    });
  });
}