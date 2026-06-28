import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/settings/replay_gain.dart';
import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:crossonic/ui/settings/pages/replay_gain_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

class _FakeKeyValue extends Fake implements KeyValueRepository {
  @override
  Future<void> store<T>(String key, T value) async {}
  @override
  Future<void> remove(String key) async {}
  @override
  Future<String?> loadString(String key) async => null;
  @override
  Future<bool?> loadBool(String key) async => null;
  @override
  Future<double?> loadDouble(String key) async => null;
}

void main() {
  late MockSettingsRepository settings;
  late ReplayGainSettings replayGain;

  setUp(() {
    settings = MockSettingsRepository();
    replayGain = ReplayGainSettings(keyValueRepository: _FakeKeyValue());
    when(() => settings.replayGain).thenReturn(replayGain);
  });

  ReplayGainViewModel buildViewModel() =>
      ReplayGainViewModel(settings: settings);

  test('constructor reads mode/preferServerFallback/fallbackGain', () {
    final vm = buildViewModel();
    expect(vm.mode, replayGain.mode);
    expect(vm.preferServerFallback, replayGain.preferServerFallbackGain);
    expect(vm.fallbackGain, replayGain.fallbackGain);
    vm.dispose();
  });

  test('settings notification re-reads and notifies', () {
    final vm = buildViewModel();
    var notifications = 0;
    vm.addListener(() => notifications++);

    replayGain.mode = ReplayGainMode.track;

    expect(vm.mode, ReplayGainMode.track);
    expect(notifications, greaterThanOrEqualTo(1));
    vm.dispose();
  });

  test('update sets all three fields on underlying settings', () {
    final vm = buildViewModel();
    vm.update(
      mode: ReplayGainMode.album,
      preferServerFallback: false,
      fallbackGain: -6.0,
    );
    expect(replayGain.mode, ReplayGainMode.album);
    expect(replayGain.preferServerFallbackGain, isFalse);
    expect(replayGain.fallbackGain, -6.0);
    vm.dispose();
  });

  test('reset restores defaults on underlying settings', () {
    replayGain.mode = ReplayGainMode.track;
    final vm = buildViewModel();
    vm.reset();
    expect(replayGain.mode, ReplayGainMode.disabled);
    vm.dispose();
  });
}