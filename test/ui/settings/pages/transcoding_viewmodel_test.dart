import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:crossonic/data/repositories/settings/transcoding.dart';
import 'package:crossonic/data/repositories/subsonic/server_support.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/settings/pages/transcoding_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockSubsonicRepository extends Mock implements SubsonicRepository {}

class MockServerSupport extends Mock implements ServerSupport {}

class _FakeKeyValue extends Fake implements KeyValueRepository {
  @override
  Future<void> store<T>(String key, T value) async {}
  @override
  Future<void> remove(String key) async {}
  @override
  Future<String?> loadString(String key) async => null;
  @override
  Future<int?> loadInt(String key) async => null;
  @override
  Future<bool?> loadBool(String key) async => null;
}

void main() {
  late MockSettingsRepository settings;
  late TranscodingSettings transcoding;
  late MockSubsonicRepository subsonic;
  late MockServerSupport supports;

  setUp(() {
    settings = MockSettingsRepository();
    subsonic = MockSubsonicRepository();
    supports = MockServerSupport();
    when(() => subsonic.supports).thenReturn(supports);
    when(() => supports.transcodeOffset).thenReturn(false);
    when(() => supports.transcodeCodecs)
        .thenReturn([TranscodingCodec.mp3, TranscodingCodec.opus]);

    transcoding = TranscodingSettings(
      keyValueRepository: _FakeKeyValue(),
      subsonicRepository: subsonic,
    );
    when(() => settings.transcoding).thenReturn(transcoding);
  });

  TranscodingViewModel buildViewModel() =>
      TranscodingViewModel(settings: settings);

  group('constructor', () {
    test('reads codec/bitRate values from settings', () {
      final vm = buildViewModel();
      expect(vm.codec, transcoding.codec);
      expect(vm.codecMobile, transcoding.codecMobile);
      expect(vm.maxBitRate, transcoding.maxBitRate);
      expect(vm.maxBitRateMobile, transcoding.maxBitRateMobile);
      vm.dispose();
    });

    test('notifies on construction via _onTranscodingChanged', () {
      var notifications = 0;
      final vm = buildViewModel();
      vm.addListener(() => notifications++);
      // already notified once in constructor; next settings change fires again
      transcoding.notifyListeners();
      expect(notifications, greaterThanOrEqualTo(1));
      vm.dispose();
    });
  });

  group('settings notification', () {
    test('transcoding change re-reads all fields and notifies', () {
      final vm = buildViewModel();
      var notifications = 0;
      vm.addListener(() => notifications++);

      transcoding.maxBitRate = 192;

      expect(vm.maxBitRate, 192);
      expect(notifications, greaterThanOrEqualTo(1));
      vm.dispose();
    });
  });

  group('updateCodec', () {
    test('sets codec on underlying settings and resets maxBitRate', () {
      final vm = buildViewModel();
      transcoding.maxBitRate = 192;

      vm.updateCodec(TranscodingCodec.mp3);

      expect(transcoding.codec, TranscodingCodec.mp3);
      expect(transcoding.maxBitRate, 256);
      vm.dispose();
    });
  });

  group('updateCodecMobile', () {
    test('sets codecMobile on underlying settings and resets maxBitRateMobile', () {
      final vm = buildViewModel();
      transcoding.maxBitRateMobile = 64;

      vm.updateCodecMobile(TranscodingCodec.opus);

      expect(transcoding.codecMobile, TranscodingCodec.opus);
      expect(transcoding.maxBitRateMobile, 128);
      vm.dispose();
    });
  });

  group('updateBitRate', () {
    test('sets maxBitRate on underlying settings', () {
      final vm = buildViewModel();
      vm.updateBitRate(320);
      expect(transcoding.maxBitRate, 320);
      vm.dispose();
    });
  });

  group('updateBitRateMobile', () {
    test('sets maxBitRateMobile on underlying settings', () {
      final vm = buildViewModel();
      vm.updateBitRateMobile(64);
      expect(transcoding.maxBitRateMobile, 64);
      vm.dispose();
    });
  });

  group('supportsMobile', () {
    test('pass-through from transcoding settings', () {
      final vm = buildViewModel();
      expect(vm.supportsMobile, transcoding.supportsMobile);
      vm.dispose();
    });
  });

  group('availableCodecs', () {
    test('pass-through from transcoding settings', () {
      final vm = buildViewModel();
      expect(vm.availableCodecs, transcoding.availableCodecs);
      vm.dispose();
    });
  });

  group('dispose', () {
    test('removes listener so settings changes no longer notify', () {
      final vm = buildViewModel();
      var notifications = 0;
      vm.addListener(() => notifications++);
      vm.dispose();

      transcoding.maxBitRate = 320;

      expect(notifications, 0);
    });
  });
}